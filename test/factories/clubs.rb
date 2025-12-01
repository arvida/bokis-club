FactoryBot.define do
  factory :club do
    sequence(:name) { |n| "Bokcirkel #{n}" }
    description { "En mysig bokcirkel för bokälskare" }
    privacy { "closed" }
  end
end
