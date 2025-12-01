require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "valid membership with user and club" do
    membership = build(:membership)
    assert membership.valid?
  end

  test "user is required" do
    membership = build(:membership, user: nil)
    assert_not membership.valid?
    assert_includes membership.errors[:user], "måste finnas"
  end

  test "club is required" do
    membership = build(:membership, club: nil)
    assert_not membership.valid?
    assert_includes membership.errors[:club], "måste finnas"
  end

  test "role defaults to member" do
    membership = Membership.new
    assert_equal "member", membership.role
  end

  test "role must be admin or member" do
    membership = build(:membership, role: "invalid")
    assert_not membership.valid?
    assert_includes membership.errors[:role], "finns inte i listan"
  end

  test "role can be set to admin" do
    membership = build(:membership, role: "admin")
    assert membership.valid?
  end

  test "membership is unique per user-club pair" do
    existing = create(:membership)
    duplicate = build(:membership, user: existing.user, club: existing.club)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "används redan"
  end

  test "deleted_at defaults to nil" do
    membership = create(:membership)
    assert_nil membership.deleted_at
  end

  test "soft_deleted? returns false when deleted_at is nil" do
    membership = build(:membership, deleted_at: nil)
    assert_not membership.soft_deleted?
  end

  test "soft_deleted? returns true when deleted_at is present" do
    membership = build(:membership, deleted_at: Time.current)
    assert membership.soft_deleted?
  end

  test "soft_delete! sets deleted_at" do
    membership = create(:membership)
    assert_nil membership.deleted_at

    membership.soft_delete!

    assert_not_nil membership.deleted_at
    assert membership.soft_deleted?
  end

  test "active scope excludes soft deleted memberships" do
    active = create(:membership)
    deleted = create(:membership)
    deleted.soft_delete!

    assert_includes Membership.active, active
    assert_not_includes Membership.active, deleted
  end

  test "admin? returns true for admin role" do
    membership = build(:membership, role: "admin")
    assert membership.admin?
  end

  test "admin? returns false for member role" do
    membership = build(:membership, role: "member")
    assert_not membership.admin?
  end
end
