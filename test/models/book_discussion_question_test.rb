require "test_helper"

class BookDiscussionQuestionTest < ActiveSupport::TestCase
  test "valid question with required attributes" do
    question = build(:book_discussion_question)
    assert question.valid?
  end

  test "text is required" do
    question = build(:book_discussion_question, text: nil)
    assert_not question.valid?
    assert_includes question.errors[:text], "måste anges"
  end

  test "book is required" do
    question = build(:book_discussion_question, book: nil)
    assert_not question.valid?
  end

  test "source must be valid" do
    question = build(:book_discussion_question, source: "invalid")
    assert_not question.valid?
    assert_includes question.errors[:source], "finns inte i listan"
  end

  test "source can be ai_generated" do
    question = build(:book_discussion_question, source: "ai_generated")
    assert question.valid?
  end

  test "source can be user_added" do
    question = build(:book_discussion_question, source: "user_added")
    assert question.valid?
  end

  test "language must be valid" do
    question = build(:book_discussion_question, language: "fr")
    assert_not question.valid?
    assert_includes question.errors[:language], "finns inte i listan"
  end

  test "language can be sv" do
    question = build(:book_discussion_question, language: "sv")
    assert question.valid?
  end

  test "language can be en" do
    question = build(:book_discussion_question, language: "en")
    assert question.valid?
  end

  test "language defaults to sv" do
    question = BookDiscussionQuestion.new
    assert_equal "sv", question.language
  end

  test "for_language scope filters by language" do
    book = create(:book)
    sv_question = create(:book_discussion_question, book: book, language: "sv")
    en_question = create(:book_discussion_question, :english, book: book)

    assert_includes BookDiscussionQuestion.for_language("sv"), sv_question
    assert_not_includes BookDiscussionQuestion.for_language("sv"), en_question
    assert_includes BookDiscussionQuestion.for_language("en"), en_question
    assert_not_includes BookDiscussionQuestion.for_language("en"), sv_question
  end

  test "fresh scope returns questions created within 6 months" do
    book = create(:book)
    fresh_question = create(:book_discussion_question, book: book)
    stale_question = create(:book_discussion_question, :stale, book: book)

    assert_includes BookDiscussionQuestion.fresh, fresh_question
    assert_not_includes BookDiscussionQuestion.fresh, stale_question
  end

  test "ai_generated scope returns only ai generated questions" do
    book = create(:book)
    ai_question = create(:book_discussion_question, :ai_generated, book: book)
    user_question = create(:book_discussion_question, :user_added, book: book)

    assert_includes BookDiscussionQuestion.ai_generated, ai_question
    assert_not_includes BookDiscussionQuestion.ai_generated, user_question
  end

  test "user_added scope returns only user added questions" do
    book = create(:book)
    ai_question = create(:book_discussion_question, :ai_generated, book: book)
    user_question = create(:book_discussion_question, :user_added, book: book)

    assert_includes BookDiscussionQuestion.user_added, user_question
    assert_not_includes BookDiscussionQuestion.user_added, ai_question
  end

  test "random_sample returns specified number of questions" do
    book = create(:book)
    5.times { create(:book_discussion_question, book: book) }

    sample = book.discussion_questions.random_sample(3)

    assert_equal 3, sample.count
  end

  test "book association works correctly" do
    book = create(:book)
    question = create(:book_discussion_question, book: book)

    assert_equal book, question.book
    assert_includes book.discussion_questions, question
  end

  test "destroying book destroys associated questions" do
    book = create(:book)
    create(:book_discussion_question, book: book)

    assert_difference "BookDiscussionQuestion.count", -1 do
      book.destroy
    end
  end
end
