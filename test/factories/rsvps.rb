FactoryBot.define do
  factory :rsvp do
    meeting
    user
    response { "yes" }

    after(:build) do |rsvp|
      if rsvp.meeting && rsvp.user && !rsvp.meeting.club.member?(rsvp.user)
        create(:membership, user: rsvp.user, club: rsvp.meeting.club)
      end
    end
  end
end
