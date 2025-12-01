FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Anna Svensson" }
    locale { "sv" }
  end
end
