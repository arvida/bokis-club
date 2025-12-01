require "test_helper"

class MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, name: "Admin User")
    @member = create(:user, name: "Member User")
    @club = create(:club)
    create(:membership, user: @admin, club: @club, role: "admin")
    create(:membership, user: @member, club: @club, role: "member")
  end

  test "index redirects to login when not authenticated" do
    get club_members_path(@club)
    assert_redirected_to login_path
  end

  test "index redirects non-members to club page" do
    non_member = create(:user)
    sign_in_as(non_member)

    get club_members_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "index shows members list for member" do
    sign_in_as(@member)

    get club_members_path(@club)
    assert_response :success
    assert_select "h1", text: I18n.t("members.index.title")
  end

  test "index shows all members" do
    sign_in_as(@member)

    get club_members_path(@club)
    assert_response :success
    assert_select ".member-row", count: 2
  end

  test "index shows invite section for admin" do
    sign_in_as(@admin)

    get club_members_path(@club)
    assert_response :success
    assert_select "[data-testid='invite-section']"
  end

  test "index hides invite section for non-admin" do
    sign_in_as(@member)

    get club_members_path(@club)
    assert_response :success
    assert_select "[data-testid='invite-section']", count: 0
  end

  test "index shows admin badge for admin members" do
    sign_in_as(@member)

    get club_members_path(@club)
    assert_response :success
    assert_select ".admin-badge"
  end

  test "index does not show soft-deleted members" do
    sign_in_as(@admin)
    @member.memberships.find_by(club: @club).soft_delete!

    get club_members_path(@club)
    assert_response :success
    assert_select ".member-row", count: 1
  end

  test "destroy removes member (admin action)" do
    sign_in_as(@admin)

    assert_difference("Membership.active.count", -1) do
      delete club_member_path(@club, @member)
    end

    assert_redirected_to club_members_path(@club)
  end

  test "destroy fails for non-admin" do
    other_member = create(:user)
    create(:membership, user: other_member, club: @club, role: "member")
    sign_in_as(@member)

    assert_no_difference("Membership.active.count") do
      delete club_member_path(@club, other_member)
    end

    assert_redirected_to club_members_path(@club)
  end

  test "destroy prevents removing admin" do
    sign_in_as(@admin)

    assert_no_difference("Membership.active.count") do
      delete club_member_path(@club, @admin)
    end

    assert_redirected_to club_members_path(@club)
  end

  test "promote makes member an admin" do
    sign_in_as(@admin)
    membership = @member.memberships.find_by(club: @club)

    assert_equal "member", membership.role

    patch promote_club_member_path(@club, @member)

    assert_redirected_to club_members_path(@club)
    assert_equal "admin", membership.reload.role
  end

  test "promote fails for non-admin" do
    other_member = create(:user)
    create(:membership, user: other_member, club: @club, role: "member")
    sign_in_as(@member)

    patch promote_club_member_path(@club, other_member)

    assert_redirected_to club_members_path(@club)
    membership = other_member.memberships.find_by(club: @club)
    assert_equal "member", membership.role
  end

  test "promote fails for non-existent member" do
    sign_in_as(@admin)
    non_member = create(:user)

    patch promote_club_member_path(@club, non_member)

    assert_redirected_to club_members_path(@club)
  end

  test "promote does nothing for already admin" do
    sign_in_as(@admin)
    membership = @admin.memberships.find_by(club: @club)

    patch promote_club_member_path(@club, @admin)

    assert_redirected_to club_members_path(@club)
    assert_equal "admin", membership.reload.role
  end
end
