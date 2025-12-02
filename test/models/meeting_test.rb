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
end
