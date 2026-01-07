FactoryBot.define do
  factory :meeting_comment do
    association :meeting, factory: :meeting, state: "live"
    user
    content { "Detta var en intressant diskussion!" }

    after(:build) do |comment|
      if comment.meeting && comment.user && !comment.meeting.club.member?(comment.user)
        create(:membership, user: comment.user, club: comment.meeting.club)
      end
    end
  end
end
