FactoryBot.define do
  factory :club_book do
    club
    book
    status { "suggested" }
    suggested_by { nil }
    notes { nil }
  end
end
