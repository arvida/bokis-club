require "test_helper"

class RsvpTest < ActiveSupport::TestCase
  test "valid RSVP with required attributes" do
    rsvp = build(:rsvp)
    assert rsvp.valid?
  end

  test "meeting is required" do
    rsvp = build(:rsvp, meeting: nil)
    assert_not rsvp.valid?
  end

  test "user is required" do
    rsvp = build(:rsvp, user: nil)
    assert_not rsvp.valid?
  end

  test "response is required" do
    rsvp = build(:rsvp, response: nil)
    assert_not rsvp.valid?
  end

  test "response must be valid" do
    rsvp = build(:rsvp, response: "invalid")
    assert_not rsvp.valid?
    assert_includes rsvp.errors[:response], "finns inte i listan"
  end

  test "response can be yes" do
    rsvp = build(:rsvp, response: "yes")
    assert rsvp.valid?
  end

  test "response can be maybe" do
    rsvp = build(:rsvp, response: "maybe")
    assert rsvp.valid?
  end

  test "response can be no" do
    rsvp = build(:rsvp, response: "no")
    assert rsvp.valid?
  end

  test "one RSVP per user per meeting" do
    user = create(:user)
    club = create(:club)
    create(:membership, user: user, club: club)
    meeting = create(:meeting, club: club)
    create(:rsvp, user: user, meeting: meeting)

    duplicate = build(:rsvp, user: user, meeting: meeting)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "har redan svarat på denna träff"
  end

  test "user can RSVP to different meetings" do
    user = create(:user)
    club = create(:club)
    create(:membership, user: user, club: club)
    meeting1 = create(:meeting, club: club)
    meeting2 = create(:meeting, club: club)

    create(:rsvp, user: user, meeting: meeting1)
    rsvp2 = build(:rsvp, user: user, meeting: meeting2)
    assert rsvp2.valid?
  end

  test "user must be member of club" do
    user = create(:user)
    club = create(:club)
    meeting = create(:meeting, club: club)

    rsvp = Rsvp.new(user: user, meeting: meeting, response: "yes")
    assert_not rsvp.valid?
    assert_includes rsvp.errors[:user], "måste vara medlem i klubben"
  end

  test "checked_in? returns false when not checked in" do
    rsvp = create(:rsvp)
    assert_not rsvp.checked_in?
  end

  test "checked_in? returns true when checked in" do
    rsvp = create(:rsvp, checked_in_at: Time.current)
    assert rsvp.checked_in?
  end

  test "check_in! sets checked_in_at" do
    rsvp = create(:rsvp, response: "yes")

    assert rsvp.check_in!
    assert rsvp.reload.checked_in?
    assert_not_nil rsvp.checked_in_at
  end

  test "check_in! returns false if already checked in" do
    rsvp = create(:rsvp, response: "yes", checked_in_at: Time.current)

    assert_not rsvp.check_in!
  end

  test "check_in! returns false if response is not yes" do
    rsvp = create(:rsvp, response: "maybe")

    assert_not rsvp.check_in!
    assert_not rsvp.reload.checked_in?
  end

  test "undo_check_in! clears checked_in_at" do
    rsvp = create(:rsvp, checked_in_at: Time.current)

    assert rsvp.undo_check_in!
    assert_not rsvp.reload.checked_in?
  end

  test "undo_check_in! returns false if not checked in" do
    rsvp = create(:rsvp)

    assert_not rsvp.undo_check_in!
  end

  test "checked_in scope returns only checked in rsvps" do
    rsvp1 = create(:rsvp, checked_in_at: Time.current)
    rsvp2 = create(:rsvp)

    assert_includes Rsvp.checked_in, rsvp1
    assert_not_includes Rsvp.checked_in, rsvp2
  end
end
