FactoryBot.define do
  factory :vote do
    association :club_book, status: "voting"
    user
  end
end
