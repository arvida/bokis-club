class DiscussionQuestionGenerator
  QUESTIONS_PER_GENERATION = 3
  CACHE_EXPIRY = 6.months

  FALLBACK_QUESTIONS_SV = [
    "Skulle du vilja hänga med huvudpersonen?",
    "Vilken scen sitter kvar i huvudet?",
    "Påminde boken dig om något i ditt eget liv?"
  ].freeze

  FALLBACK_QUESTIONS_EN = [
    "Would you want to hang out with the main character?",
    "Which scene is stuck in your head?",
    "Did the book remind you of anything in your own life?"
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
      You are creating discussion questions for a book club of friends who read a lot.
      They want real conversation, not a literature seminar.

      Your questions should:
      - Sound like something a friend would ask over drinks
      - Be SHORT: one sentence, max 12 words
      - Go beyond "what did you think" but stay grounded
      - Connect to real life, feelings, or experiences
      - Be specific to the book when possible

      Tone: Curious, direct, a bit cheeky. Like a smart friend who's genuinely interested.

      Avoid: Academic language, philosophical abstractions, "moral responsibility",
      "the human condition", anything that sounds like a thesis question.

      Bad example: "Hur påverkar detta din syn på författarens moraliska ansvar?"
      Good example: "Skulle du kunna vara vän med huvudpersonen?"

      IMPORTANT: Write in #{language_name}.
      Respond ONLY with questions, one per line, no numbering.
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
