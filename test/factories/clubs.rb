FactoryBot.define do
  factory :club do
    sequence(:name) { |n| "Bokklubb #{n}" }
    description { "En mysig bokklubb för bokälskare" }
    privacy { "closed" }
  end
end
