FactoryBot.define do
  factory :discussion_guide do
    meeting
    items { [] }

    trait :with_items do
      items do
        [
          { "id" => SecureRandom.uuid, "text" => "Vad tyckte du om boken?", "checked" => false, "source" => "ai_generated" },
          { "id" => SecureRandom.uuid, "text" => "Vilken karaktär var din favorit?", "checked" => false, "source" => "ai_generated" },
          { "id" => SecureRandom.uuid, "text" => "Vad var bokens tema?", "checked" => false, "source" => "user_added" }
        ]
      end
    end
  end
end
