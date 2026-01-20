FactoryBot.define do
  factory :message_reply do
    message
    user
    content { "Jag höll med om det mesta!" }

    after(:build) do |reply|
      club = reply.message&.club
      if club && reply.user && !club.member?(reply.user)
        create(:membership, user: reply.user, club: club)
      end
    end
  end
end
