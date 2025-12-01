require "test_helper"

class ClubTest < ActiveSupport::TestCase
  test "valid club with all required attributes" do
    club = build(:club)
    assert club.valid?
  end

  test "name is required" do
    club = build(:club, name: nil)
    assert_not club.valid?
    assert_includes club.errors[:name], "måste anges"
  end

  test "name must not exceed 100 characters" do
    club = build(:club, name: "A" * 101)
    assert_not club.valid?
    assert_includes club.errors[:name], "är för lång (max 100 tecken)"
  end

  test "description is optional" do
    club = build(:club, description: nil)
    assert club.valid?
  end

  test "description must not exceed 500 characters" do
    club = build(:club, description: "A" * 501)
    assert_not club.valid?
    assert_includes club.errors[:description], "är för lång (max 500 tecken)"
  end

  test "privacy defaults to closed" do
    club = Club.new(name: "Test Club")
    assert_equal "closed", club.privacy
  end

  test "privacy must be open or closed" do
    club = build(:club, privacy: "invalid")
    assert_not club.valid?
    assert_includes club.errors[:privacy], "finns inte i listan"
  end

  test "privacy can be set to open" do
    club = build(:club, privacy: "open")
    assert club.valid?
  end

  test "invite_code is auto-generated on create" do
    club = create(:club)
    assert_not_nil club.invite_code
    assert_equal 8, club.invite_code.length
  end

  test "invite_code is lowercase alphanumeric" do
    club = create(:club)
    assert_match(/\A[a-z0-9]{8}\z/, club.invite_code)
  end

  test "invite_code is unique" do
    club1 = create(:club)
    club2 = build(:club, invite_code: club1.invite_code)
    assert_not club2.valid?
    assert_includes club2.errors[:invite_code], "används redan"
  end

  test "invite_code is not regenerated on update" do
    club = create(:club)
    original_code = club.invite_code
    club.update!(name: "New Name")
    assert_equal original_code, club.invite_code
  end

  test "deleted_at defaults to nil" do
    club = create(:club)
    assert_nil club.deleted_at
  end

  test "soft_deleted? returns false when deleted_at is nil" do
    club = build(:club, deleted_at: nil)
    assert_not club.soft_deleted?
  end

  test "soft_deleted? returns true when deleted_at is present" do
    club = build(:club, deleted_at: Time.current)
    assert club.soft_deleted?
  end

  test "soft_delete! sets deleted_at" do
    club = create(:club)
    assert_nil club.deleted_at

    club.soft_delete!

    assert_not_nil club.deleted_at
    assert club.soft_deleted?
  end

  test "active scope excludes soft deleted clubs" do
    active_club = create(:club)
    deleted_club = create(:club)
    deleted_club.soft_delete!

    assert_includes Club.active, active_club
    assert_not_includes Club.active, deleted_club
  end

  test "regenerate_invite_code! creates new code" do
    club = create(:club)
    original_code = club.invite_code

    club.regenerate_invite_code!

    assert_not_equal original_code, club.invite_code
    assert_equal 8, club.invite_code.length
  end

  test "club has many memberships" do
    club = create(:club)
    user1 = create(:user)
    user2 = create(:user)
    create(:membership, club: club, user: user1)
    create(:membership, club: club, user: user2)

    assert_equal 2, club.memberships.count
  end

  test "club has many members through memberships" do
    club = create(:club)
    user = create(:user)
    create(:membership, club: club, user: user)

    assert_includes club.members, user
  end

  test "club.admins returns admin members" do
    club = create(:club)
    admin = create(:user)
    member = create(:user)
    create(:membership, club: club, user: admin, role: "admin")
    create(:membership, club: club, user: member, role: "member")

    assert_includes club.admins, admin
    assert_not_includes club.admins, member
  end

  test "club.admin? returns true for admin" do
    club = create(:club)
    admin = create(:user)
    create(:membership, club: club, user: admin, role: "admin")

    assert club.admin?(admin)
  end

  test "club.admin? returns false for member" do
    club = create(:club)
    member = create(:user)
    create(:membership, club: club, user: member, role: "member")

    assert_not club.admin?(member)
  end

  test "club.admin? returns false for non-member" do
    club = create(:club)
    non_member = create(:user)

    assert_not club.admin?(non_member)
  end

  test "club.member? returns true for any membership" do
    club = create(:club)
    user = create(:user)
    create(:membership, club: club, user: user, role: "member")

    assert club.member?(user)
  end

  test "club.member? returns false for non-member" do
    club = create(:club)
    non_member = create(:user)

    assert_not club.member?(non_member)
  end

  test "memberships excludes soft deleted" do
    club = create(:club)
    active_member = create(:user)
    deleted_member = create(:user)
    create(:membership, club: club, user: active_member)
    deleted_membership = create(:membership, club: club, user: deleted_member)
    deleted_membership.soft_delete!

    assert_equal 1, club.memberships.count
    assert_includes club.members, active_member
    assert_not_includes club.members, deleted_member
  end

  test "cover_library_id can be set" do
    club = build(:club, cover_library_id: "library-1")
    assert_equal "library-1", club.cover_library_id
  end

  test "cover_url returns library asset path when cover_library_id set" do
    club = build(:club, cover_library_id: "library-1")
    assert_equal "covers/library-1.jpg", club.cover_url
  end

  test "cover_url returns default when neither cover set" do
    club = build(:club, cover_library_id: nil)
    assert_equal "covers/default.jpg", club.cover_url
  end

  test "COVER_IMAGES constant contains library images" do
    assert Club::COVER_IMAGES.is_a?(Array)
    assert Club::COVER_IMAGES.length >= 8
    assert Club::COVER_IMAGES.all? { |img| img[:id].present? && img[:path].present? }
  end

  test "invite_valid? returns true for fresh invite" do
    club = create(:club)
    assert club.invite_valid?
  end

  test "invite_valid? returns false when invite used" do
    club = create(:club, invite_used_at: Time.current)
    assert_not club.invite_valid?
  end

  test "invite_valid? returns false when invite expired" do
    club = create(:club, invite_expires_at: 1.day.ago)
    assert_not club.invite_valid?
  end

  test "invite_valid? returns true when invite not yet expired" do
    club = create(:club, invite_expires_at: 1.day.from_now)
    assert club.invite_valid?
  end

  test "mark_invite_used! sets invite_used_at" do
    club = create(:club)
    assert_nil club.invite_used_at

    club.mark_invite_used!

    assert_not_nil club.invite_used_at
  end

  test "regenerate_invite_code! resets expiration and used_at" do
    club = create(:club, invite_expires_at: 1.day.ago, invite_used_at: 1.day.ago)
    original_code = club.invite_code

    club.regenerate_invite_code!

    assert_not_equal original_code, club.invite_code
    assert_nil club.invite_used_at
    assert club.invite_expires_at > Time.current
  end

  test "invite_url returns full URL with invite code" do
    club = create(:club)
    url = club.invite_url

    assert_includes url, club.invite_code
    assert_includes url, "bjud-in"
  end
end
