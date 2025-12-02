FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Bok #{n}" }
    authors { [ "Författare Namn" ] }
    description { "En spännande bok om livet och allt annat." }
    page_count { 320 }
    cover_url { nil }
    isbn { nil }
    google_books_id { nil }
  end
end
