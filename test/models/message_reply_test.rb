require "test_helper"

class MessageReplyTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    reply = build(:message_reply)
    assert reply.valid?
  end

  test "message is required" do
    reply = build(:message_reply, message: nil)
    assert_not reply.valid?
    assert_includes reply.errors[:message], "måste finnas"
  end

  test "user is required" do
    reply = build(:message_reply, user: nil)
    assert_not reply.valid?
    assert_includes reply.errors[:user], "måste finnas"
  end

  test "content is required" do
    reply = build(:message_reply, content: nil)
    assert_not reply.valid?
    assert_includes reply.errors[:content], "måste anges"
  end

  test "content cannot be blank" do
    reply = build(:message_reply, content: "")
    assert_not reply.valid?
    assert_includes reply.errors[:content], "måste anges"
  end

  test "content cannot exceed 1000 characters" do
    reply = build(:message_reply, content: "a" * 1001)
    assert_not reply.valid?
    assert_includes reply.errors[:content], "är för lång (max 1000 tecken)"
  end

  test "content at 1000 characters is valid" do
    reply = build(:message_reply, content: "a" * 1000)
    assert reply.valid?
  end

  test "editable_by? returns true for author within 15 minutes" do
    reply = create(:message_reply)
    assert reply.editable_by?(reply.user)
  end

  test "editable_by? returns false for author after 15 minutes" do
    reply = create(:message_reply, created_at: 16.minutes.ago)
    assert_not reply.editable_by?(reply.user)
  end

  test "editable_by? returns false for other users" do
    reply = create(:message_reply)
    other_user = create(:user)
    assert_not reply.editable_by?(other_user)
  end

  test "editable_by? returns false for nil user" do
    reply = create(:message_reply)
    assert_not reply.editable_by?(nil)
  end

  test "destroyable_by? returns true for author" do
    reply = create(:message_reply)
    assert reply.destroyable_by?(reply.user)
  end

  test "destroyable_by? returns true for club admin" do
    club = create(:club)
    author = create(:user)
    admin = create(:user)
    create(:membership, user: author, club: club, role: "member")
    create(:membership, user: admin, club: club, role: "admin")

    message = create(:message, club: club, user: author)
    reply = create(:message_reply, message: message, user: author)

    assert reply.destroyable_by?(admin)
  end

  test "destroyable_by? returns false for non-admin members" do
    club = create(:club)
    author = create(:user)
    other_member = create(:user)
    create(:membership, user: author, club: club, role: "member")
    create(:membership, user: other_member, club: club, role: "member")

    message = create(:message, club: club, user: author)
    reply = create(:message_reply, message: message, user: author)

    assert_not reply.destroyable_by?(other_member)
  end

  test "destroyable_by? returns false for nil user" do
    reply = create(:message_reply)
    assert_not reply.destroyable_by?(nil)
  end

  test "edited? returns false when edited_at is nil" do
    reply = build(:message_reply, edited_at: nil)
    assert_not reply.edited?
  end

  test "edited? returns true when edited_at is set" do
    reply = build(:message_reply, edited_at: Time.current)
    assert reply.edited?
  end

  test "club returns the message club" do
    club = create(:club)
    user = create(:user)
    create(:membership, user: user, club: club)
    message = create(:message, club: club, user: user)
    reply = create(:message_reply, message: message, user: user)

    assert_equal club, reply.club
  end
end
