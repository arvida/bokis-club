FactoryBot.define do
  factory :membership do
    user
    club
    role { "member" }

    trait :admin do
      role { "admin" }
    end
  end
end
