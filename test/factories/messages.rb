FactoryBot.define do
  factory :message do
    club
    user
    content { "Hej alla! Vad tyckte ni om förra boken?" }

    after(:build) do |message|
      if message.club && message.user && !message.club.member?(message.user)
        create(:membership, user: message.user, club: message.club)
      end
    end
  end
end
