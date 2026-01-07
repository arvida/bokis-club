require "test_helper"

class MeetingTest < ActiveSupport::TestCase
  test "valid meeting with required attributes" do
    meeting = build(:meeting)
    assert meeting.valid?
  end

  test "title is required" do
    meeting = build(:meeting, title: nil)
    assert_not meeting.valid?
    assert_includes meeting.errors[:title], "måste anges"
  end

  test "scheduled_at is required" do
    meeting = build(:meeting, scheduled_at: nil)
    assert_not meeting.valid?
    assert_includes meeting.errors[:scheduled_at], "måste anges"
  end

  test "club is required" do
    meeting = build(:meeting, club: nil)
    assert_not meeting.valid?
  end

  test "club_book is optional" do
    meeting = build(:meeting, club_book: nil)
    assert meeting.valid?
  end

  test "ends_at must be after scheduled_at if present" do
    meeting = build(:meeting, scheduled_at: 1.day.from_now, ends_at: 1.day.ago)
    assert_not meeting.valid?
    assert_includes meeting.errors[:ends_at], "måste vara efter starttid"
  end

  test "ends_at is valid when after scheduled_at" do
    meeting = build(:meeting, scheduled_at: 1.day.from_now, ends_at: 1.day.from_now + 2.hours)
    assert meeting.valid?
  end

  test "location_type defaults to tbd" do
    meeting = Meeting.new
    assert_equal "tbd", meeting.location_type
  end

  test "location_type must be valid" do
    meeting = build(:meeting, location_type: "invalid")
    assert_not meeting.valid?
    assert_includes meeting.errors[:location_type], "finns inte i listan"
  end

  test "location_type can be physical" do
    meeting = build(:meeting, location_type: "physical")
    assert meeting.valid?
  end

  test "location_type can be video" do
    meeting = build(:meeting, location_type: "video")
    assert meeting.valid?
  end

  test "active scope excludes soft deleted" do
    active_meeting = create(:meeting)
    deleted_meeting = create(:meeting)
    deleted_meeting.soft_delete!

    assert_includes Meeting.active, active_meeting
    assert_not_includes Meeting.active, deleted_meeting
  end

  test "upcoming scope returns future meetings" do
    past_meeting = create(:meeting, scheduled_at: 1.day.ago)
    future_meeting = create(:meeting, scheduled_at: 1.day.from_now)

    assert_includes Meeting.upcoming, future_meeting
    assert_not_includes Meeting.upcoming, past_meeting
  end

  test "past scope returns past meetings" do
    past_meeting = create(:meeting, scheduled_at: 1.day.ago)
    future_meeting = create(:meeting, scheduled_at: 1.day.from_now)

    assert_includes Meeting.past, past_meeting
    assert_not_includes Meeting.past, future_meeting
  end

  test "soft_delete! sets deleted_at" do
    meeting = create(:meeting)
    assert_nil meeting.deleted_at

    meeting.soft_delete!

    assert_not_nil meeting.deleted_at
  end

  test "duration returns nil when ends_at is nil" do
    meeting = build(:meeting, ends_at: nil)
    assert_nil meeting.duration
  end

  test "duration returns minutes between scheduled_at and ends_at" do
    meeting = build(:meeting, scheduled_at: Time.current, ends_at: Time.current + 2.hours)
    assert_equal 120, meeting.duration
  end

  test "maps_url returns nil for non-physical location" do
    meeting = build(:meeting, location_type: "video", location: "https://zoom.us/j/123")
    assert_nil meeting.maps_url
  end

  test "maps_url returns nil when location blank" do
    meeting = build(:meeting, location_type: "physical", location: nil)
    assert_nil meeting.maps_url
  end

  test "maps_url returns Google Maps URL for physical location" do
    meeting = build(:meeting, location_type: "physical", location: "Storgatan 1, Stockholm")
    assert meeting.maps_url.include?("google.com/maps")
    assert meeting.maps_url.include?("Storgatan")
  end

  test "meeting belongs to club" do
    club = create(:club)
    meeting = create(:meeting, club: club)
    assert_equal club, meeting.club
  end

  test "meeting can belong to club_book" do
    club = create(:club)
    club_book = create(:club_book, club: club, status: "reading")
    meeting = create(:meeting, club: club, club_book: club_book)
    assert_equal club_book, meeting.club_book
  end

  # State machine tests
  test "state defaults to scheduled" do
    meeting = Meeting.new
    assert_equal "scheduled", meeting.state
  end

  test "state must be valid" do
    meeting = build(:meeting)
    meeting.state = "invalid"
    assert_not meeting.valid?
    assert_includes meeting.errors[:state], "finns inte i listan"
  end

  test "scheduled? returns true when state is scheduled" do
    meeting = build(:meeting, state: "scheduled")
    assert meeting.scheduled?
    assert_not meeting.live?
    assert_not meeting.ended?
  end

  test "live? returns true when state is live" do
    meeting = build(:meeting, state: "live")
    assert meeting.live?
    assert_not meeting.scheduled?
    assert_not meeting.ended?
  end

  test "ended? returns true when state is ended" do
    meeting = build(:meeting, state: "ended")
    assert meeting.ended?
    assert_not meeting.scheduled?
    assert_not meeting.live?
  end

  test "start! transitions from scheduled to live" do
    meeting = create(:meeting, state: "scheduled")

    result = meeting.start!

    assert result
    assert meeting.live?
    assert_not_nil meeting.started_at
  end

  test "start! does not change state if already live" do
    meeting = create(:meeting, state: "live", started_at: 1.hour.ago)

    result = meeting.start!

    assert_not result
    assert meeting.live?
  end

  test "start! preserves existing started_at when resuming" do
    original_started_at = 2.hours.ago
    meeting = create(:meeting, state: "ended", started_at: original_started_at)
    meeting.resume!

    assert meeting.live?
    assert_equal original_started_at.to_i, meeting.started_at.to_i
  end

  test "end! transitions from live to ended" do
    meeting = create(:meeting, state: "live", started_at: 1.hour.ago)

    result = meeting.end!

    assert result
    assert meeting.ended?
    assert_not_nil meeting.ended_at
  end

  test "end! does not change state if not live" do
    meeting = create(:meeting, state: "scheduled")

    result = meeting.end!

    assert_not result
    assert meeting.scheduled?
  end

  test "resume! transitions from ended to live" do
    meeting = create(:meeting, state: "ended", started_at: 2.hours.ago, ended_at: 1.hour.ago)

    result = meeting.resume!

    assert result
    assert meeting.live?
    assert_nil meeting.ended_at
    assert_not_nil meeting.started_at
  end

  test "resume! does not change state if not ended" do
    meeting = create(:meeting, state: "live", started_at: 1.hour.ago)

    result = meeting.resume!

    assert_not result
    assert meeting.live?
  end

  test "live scope returns only live meetings" do
    scheduled_meeting = create(:meeting, state: "scheduled")
    live_meeting = create(:meeting, state: "live", started_at: 1.hour.ago)
    ended_meeting = create(:meeting, state: "ended", started_at: 2.hours.ago, ended_at: 1.hour.ago)

    assert_includes Meeting.live, live_meeting
    assert_not_includes Meeting.live, scheduled_meeting
    assert_not_includes Meeting.live, ended_meeting
  end

  test "ended scope returns only ended meetings" do
    scheduled_meeting = create(:meeting, state: "scheduled")
    live_meeting = create(:meeting, state: "live", started_at: 1.hour.ago)
    ended_meeting = create(:meeting, state: "ended", started_at: 2.hours.ago, ended_at: 1.hour.ago)

    assert_includes Meeting.ended, ended_meeting
    assert_not_includes Meeting.ended, scheduled_meeting
    assert_not_includes Meeting.ended, live_meeting
  end

  test "regenerate_count defaults to 0" do
    meeting = Meeting.new
    assert_equal 0, meeting.regenerate_count
  end

  test "can_regenerate? returns true when count is less than 3" do
    meeting = build(:meeting, regenerate_count: 0)
    assert meeting.can_regenerate?

    meeting.regenerate_count = 2
    assert meeting.can_regenerate?
  end

  test "can_regenerate? returns false when count is 3 or more" do
    meeting = build(:meeting, regenerate_count: 3)
    assert_not meeting.can_regenerate?

    meeting.regenerate_count = 5
    assert_not meeting.can_regenerate?
  end

  test "increment_regenerate! increases count by 1" do
    meeting = create(:meeting, regenerate_count: 1)

    meeting.increment_regenerate!

    assert_equal 2, meeting.regenerate_count
  end
end
