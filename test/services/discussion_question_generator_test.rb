require "test_helper"

class MockGptClient
  attr_reader :calls

  def initialize(response:)
    @response = response
    @calls = []
  end

  def chat(messages, max_completion_tokens: 1000)
    @calls << { messages: messages }
    raise AzureGptClient::ApiError, "Test error" if @response == :error
    @response
  end
end

class DiscussionQuestionGeneratorTest < ActiveSupport::TestCase
  setup do
    @book = create(:book, title: "Test Book", authors: [ "Test Author" ], description: "A test book description")
  end

  test "generate_for_book returns existing questions if enough fresh ones exist" do
    3.times { create(:book_discussion_question, book: @book, language: "sv") }

    mock_client = MockGptClient.new(response: "Should not be called")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)
    result = generator.generate_for_book(@book, language: "sv")

    assert_equal 3, result.size
    assert_empty mock_client.calls
  end

  test "generate_for_book calls API when not enough questions exist" do
    mock_client = MockGptClient.new(response: "Fråga 1?\nFråga 2?\nFråga 3?")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    result = generator.generate_for_book(@book, language: "sv")

    assert_equal 3, result.size
    assert_equal "Fråga 1?", result.first.text
    assert result.all? { |q| q.source == "ai_generated" }
    assert_equal 1, mock_client.calls.size
  end

  test "regenerate_for_book always calls API" do
    3.times { create(:book_discussion_question, book: @book, language: "sv") }
    mock_client = MockGptClient.new(response: "Ny fråga 1?\nNy fråga 2?\nNy fråga 3?")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    result = generator.regenerate_for_book(@book, language: "sv")

    assert_equal 3, result.size
    assert_equal "Ny fråga 1?", result.first.text
    assert_equal 1, mock_client.calls.size
  end

  test "generate_for_book stores questions with correct attributes" do
    mock_client = MockGptClient.new(response: "Test question?")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    result = generator.generate_for_book(@book, language: "en")

    question = result.first
    assert_equal @book, question.book
    assert_equal "en", question.language
    assert_equal "ai_generated", question.source
  end

  test "generate_for_book returns Swedish fallback questions on API error" do
    mock_client = MockGptClient.new(response: :error)
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    result = generator.generate_for_book(@book, language: "sv")

    assert_equal 3, result.size
    assert result.all? { |q| q.source == "fallback" }
    assert_includes result.first.text, "huvudpersonen"
  end

  test "generate_for_book returns English fallback questions on API error" do
    mock_client = MockGptClient.new(response: :error)
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    result = generator.generate_for_book(@book, language: "en")

    assert_equal 3, result.size
    assert result.all? { |q| q.source == "fallback" }
    assert_includes result.first.text, "main character"
  end

  test "generate_for_book filters blank lines from response" do
    mock_client = MockGptClient.new(response: "Fråga 1?\n\n\nFråga 2?\n  \nFråga 3?")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    result = generator.generate_for_book(@book, language: "sv")

    assert_equal 3, result.size
    assert result.all? { |q| q.text.present? }
  end

  test "generate_for_book limits to 3 questions even if more returned" do
    mock_client = MockGptClient.new(response: "Q1?\nQ2?\nQ3?\nQ4?\nQ5?")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    result = generator.generate_for_book(@book, language: "sv")

    assert_equal 3, result.size
  end

  test "generate_for_book instructs response in Swedish for sv language" do
    mock_client = MockGptClient.new(response: "Fråga?")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    generator.generate_for_book(@book, language: "sv")

    system_msg = mock_client.calls.first[:messages].find { |m| m[:role] == "system" }
    assert_includes system_msg[:content], "Write in Swedish"
  end

  test "generate_for_book instructs response in English for en language" do
    mock_client = MockGptClient.new(response: "Question?")
    generator = DiscussionQuestionGenerator.new(gpt_client: mock_client)

    generator.generate_for_book(@book, language: "en")

    system_msg = mock_client.calls.first[:messages].find { |m| m[:role] == "system" }
    assert_includes system_msg[:content], "Write in English"
  end
end
