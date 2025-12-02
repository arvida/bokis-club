FactoryBot.define do
  factory :meeting do
    club
    title { "Bokcirkelmöte" }
    scheduled_at { 1.week.from_now }
    location_type { "tbd" }
  end
end
