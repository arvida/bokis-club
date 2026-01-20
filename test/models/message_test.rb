require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    message = build(:message)
    assert message.valid?
  end

  test "club is required" do
    message = build(:message, club: nil)
    assert_not message.valid?
    assert_includes message.errors[:club], "måste finnas"
  end

  test "user is required" do
    message = build(:message, user: nil)
    assert_not message.valid?
    assert_includes message.errors[:user], "måste finnas"
  end

  test "content is required" do
    message = build(:message, content: nil)
    assert_not message.valid?
    assert_includes message.errors[:content], "måste anges"
  end

  test "content cannot be blank" do
    message = build(:message, content: "")
    assert_not message.valid?
    assert_includes message.errors[:content], "måste anges"
  end

  test "content cannot exceed 2000 characters" do
    message = build(:message, content: "a" * 2001)
    assert_not message.valid?
    assert_includes message.errors[:content], "är för lång (max 2000 tecken)"
  end

  test "content at 2000 characters is valid" do
    message = build(:message, content: "a" * 2000)
    assert message.valid?
  end

  test "has many replies" do
    message = create(:message)
    reply = create(:message_reply, message: message)
    assert_includes message.replies.reload, reply
  end

  test "editable_by? returns true for author within 15 minutes" do
    message = create(:message)
    assert message.editable_by?(message.user)
  end

  test "editable_by? returns false for author after 15 minutes" do
    message = create(:message, created_at: 16.minutes.ago)
    assert_not message.editable_by?(message.user)
  end

  test "editable_by? returns false for other users" do
    message = create(:message)
    other_user = create(:user)
    assert_not message.editable_by?(other_user)
  end

  test "editable_by? returns false for nil user" do
    message = create(:message)
    assert_not message.editable_by?(nil)
  end

  test "destroyable_by? returns true for author" do
    message = create(:message)
    assert message.destroyable_by?(message.user)
  end

  test "destroyable_by? returns true for club admin" do
    club = create(:club)
    author = create(:user)
    admin = create(:user)
    create(:membership, user: author, club: club, role: "member")
    create(:membership, user: admin, club: club, role: "admin")

    message = create(:message, club: club, user: author)
    assert message.destroyable_by?(admin)
  end

  test "destroyable_by? returns false for non-admin members" do
    club = create(:club)
    author = create(:user)
    other_member = create(:user)
    create(:membership, user: author, club: club, role: "member")
    create(:membership, user: other_member, club: club, role: "member")

    message = create(:message, club: club, user: author)
    assert_not message.destroyable_by?(other_member)
  end

  test "destroyable_by? returns false for nil user" do
    message = create(:message)
    assert_not message.destroyable_by?(nil)
  end

  test "edited? returns false when edited_at is nil" do
    message = build(:message, edited_at: nil)
    assert_not message.edited?
  end

  test "edited? returns true when edited_at is set" do
    message = build(:message, edited_at: Time.current)
    assert message.edited?
  end
end
