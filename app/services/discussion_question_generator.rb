class DiscussionQuestionGenerator
  QUESTIONS_PER_GENERATION = 3
  CACHE_EXPIRY = 6.months

  FALLBACK_QUESTIONS_SV = [
    "Vad tyckte du om huvudkaraktären?",
    "Vilket tema i boken resonerade mest med dig?",
    "Fanns det något i boken som överraskade dig?"
  ].freeze

  FALLBACK_QUESTIONS_EN = [
    "What did you think of the main character?",
    "Which theme in the book resonated most with you?",
    "Was there anything in the book that surprised you?"
  ].freeze

  FallbackQuestion = Struct.new(:text, :source, keyword_init: true)

  def initialize(gpt_client: nil)
    @gpt_client = gpt_client || AzureGptClient.new
  end

  def generate_for_book(book, language:, count: QUESTIONS_PER_GENERATION)
    existing = book.discussion_questions.for_language(language).fresh.random_sample(count)
    return existing if existing.size >= count

    generate_new_questions(book, language, count)
  end

  def regenerate_for_book(book, language:, count: QUESTIONS_PER_GENERATION)
    generate_new_questions(book, language, count)
  end

  private

  def generate_new_questions(book, language, count = QUESTIONS_PER_GENERATION)
    response = @gpt_client.chat(build_prompt(book, language, count))
    questions = parse_questions(response, count)

    questions.map do |text|
      book.discussion_questions.create!(
        text: text,
        language: language,
        source: "ai_generated"
      )
    end
  rescue AzureGptClient::ApiError => e
    Rails.error.report(e, context: { book_id: book.id, language: language })
    fallback_questions(language).first(count)
  end

  def fallback_questions(language)
    questions = language == "sv" ? FALLBACK_QUESTIONS_SV : FALLBACK_QUESTIONS_EN
    questions.map { |text| FallbackQuestion.new(text: text, source: "fallback") }
  end

  def build_prompt(book, language, count)
    system_prompt = build_system_prompt(language)
    user_prompt = build_user_prompt(book, language, count)

    [
      { role: "system", content: system_prompt },
      { role: "user", content: user_prompt }
    ]
  end

  def build_system_prompt(language)
    language_name = language_name_for(language)

    <<~PROMPT.strip
      You are creating discussion questions for an intimate book club of well-read, culturally
      curious adults in their 30s and 40s. Think urban Europeans who read literary fiction,
      attend gallery openings, and appreciate nuanced conversation over natural wine.

      Your questions should:
      - Be SHORT: one sentence, max 15 words. Punchy and direct.
      - Probe deeper themes: identity, moral ambiguity, societal structures, the human condition
      - Connect literature to contemporary life and personal experience
      - Invite vulnerability and genuine reflection, not surface-level opinions
      - Be intellectually stimulating without being pretentious
      - Assume readers are thoughtful and can handle complexity

      Avoid: cliches, obvious questions, school assignment vibes, em-dashes, compound questions.

      IMPORTANT: Write your response in #{language_name}.
      Respond ONLY with the questions, one per line, without numbering or other characters.
    PROMPT
  end

  def build_user_prompt(book, _language, count)
    author_text = book.authors.presence&.join(", ") || "unknown author"

    <<~PROMPT.strip
      Create #{count} discussion questions for the book "#{book.title}" by #{author_text}.

      #{book.description.present? ? "Book description: #{book.description.truncate(500)}" : ""}

      The questions should encourage meaningful discussion and reflection.
    PROMPT
  end

  def language_name_for(code)
    {
      "sv" => "Swedish",
      "en" => "English",
      "de" => "German",
      "fr" => "French",
      "es" => "Spanish",
      "no" => "Norwegian",
      "da" => "Danish",
      "fi" => "Finnish"
    }.fetch(code, "English")
  end

  def parse_questions(response, count = QUESTIONS_PER_GENERATION)
    return [] if response.blank?

    response
      .split("\n")
      .map(&:strip)
      .reject(&:blank?)
      .take(count)
  end
end
