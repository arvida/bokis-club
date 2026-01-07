require "test_helper"

class MeetingCommentTest < ActiveSupport::TestCase
  test "valid with required attributes on live meeting" do
    comment = build(:meeting_comment)
    assert comment.valid?
  end

  test "meeting is required" do
    comment = build(:meeting_comment, meeting: nil)
    assert_not comment.valid?
  end

  test "user is required" do
    comment = build(:meeting_comment, user: nil)
    assert_not comment.valid?
  end

  test "content is required" do
    comment = build(:meeting_comment, content: nil)
    assert_not comment.valid?
  end

  test "content cannot be blank" do
    comment = build(:meeting_comment, content: "")
    assert_not comment.valid?
  end

  test "content cannot exceed 1000 characters" do
    comment = build(:meeting_comment, content: "a" * 1001)
    assert_not comment.valid?
    assert_includes comment.errors[:content], "är för lång (max 1000 tecken)"
  end

  test "content at 1000 characters is valid" do
    comment = build(:meeting_comment, content: "a" * 1000)
    assert comment.valid?
  end

  test "invalid on scheduled meeting" do
    meeting = create(:meeting, state: "scheduled")
    user = create(:user)
    create(:membership, user: user, club: meeting.club)

    comment = build(:meeting_comment, meeting: meeting, user: user)
    assert_not comment.valid?
    assert_includes comment.errors[:meeting], "måste vara live eller avslutad för att lägga till kommentarer"
  end

  test "valid on live meeting" do
    meeting = create(:meeting, state: "live")
    user = create(:user)
    create(:membership, user: user, club: meeting.club)

    comment = build(:meeting_comment, meeting: meeting, user: user)
    assert comment.valid?
  end

  test "valid on ended meeting" do
    meeting = create(:meeting, state: "ended")
    user = create(:user)
    create(:membership, user: user, club: meeting.club)

    comment = build(:meeting_comment, meeting: meeting, user: user)
    assert comment.valid?
  end

  test "editable_by? returns true for comment author" do
    comment = create(:meeting_comment)
    assert comment.editable_by?(comment.user)
  end

  test "editable_by? returns false for other users" do
    comment = create(:meeting_comment)
    other_user = create(:user)
    assert_not comment.editable_by?(other_user)
  end
end
