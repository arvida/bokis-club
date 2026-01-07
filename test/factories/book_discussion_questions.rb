FactoryBot.define do
  factory :book_discussion_question do
    book
    language { "sv" }
    text { "Vad tyckte du om huvudkaraktären?" }
    source { "ai_generated" }

    trait :ai_generated do
      source { "ai_generated" }
    end

    trait :user_added do
      source { "user_added" }
    end

    trait :english do
      language { "en" }
      text { "What did you think of the main character?" }
    end

    trait :stale do
      created_at { 7.months.ago }
    end
  end
end
