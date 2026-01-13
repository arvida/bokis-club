require "test_helper"

class ClubsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "new redirects to login when not authenticated" do
    get new_club_path
    assert_redirected_to login_path
  end

  test "create redirects to login when not authenticated" do
    post clubs_path, params: { club: { name: "Test Club" } }
    assert_redirected_to login_path
  end

  test "new shows club form when authenticated" do
    sign_in_as(@user)
    get new_club_path
    assert_response :success
    assert_select "form"
    assert_select "input[name='club[name]']"
  end

  test "create creates club with valid params" do
    sign_in_as(@user)

    assert_difference("Club.count", 1) do
      post clubs_path, params: {
        club: { name: "Min Bokklubb", description: "En mysig klubb", privacy: "closed" }
      }
    end

    club = Club.last
    assert_equal "Min Bokklubb", club.name
    assert_equal "En mysig klubb", club.description
    assert_equal "closed", club.privacy
  end

  test "create creates membership with admin role for creator" do
    sign_in_as(@user)

    assert_difference("Membership.count", 1) do
      post clubs_path, params: { club: { name: "Test Club" } }
    end

    club = Club.last
    membership = Membership.last
    assert_equal @user, membership.user
    assert_equal club, membership.club
    assert_equal "admin", membership.role
  end

  test "create redirects to club show on success" do
    sign_in_as(@user)
    post clubs_path, params: { club: { name: "Test Club" } }

    club = Club.last
    assert_redirected_to club_path(club)
  end

  test "create shows flash message on success" do
    sign_in_as(@user)
    post clubs_path, params: { club: { name: "Test Club" } }

    assert_equal I18n.t("flash.clubs.created"), flash[:notice]
  end

  test "create renders form with errors for invalid params" do
    sign_in_as(@user)
    post clubs_path, params: { club: { name: "" } }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create saves cover_library_id" do
    sign_in_as(@user)
    post clubs_path, params: {
      club: { name: "Test Club", cover_library_id: "library-1" }
    }

    club = Club.last
    assert_equal "library-1", club.cover_library_id
  end

  test "show displays club for member" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club)

    get club_path(club)
    assert_response :success
  end

  test "show returns 404 for soft-deleted club" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club)
    club.soft_delete!

    get club_path(club)
    assert_response :not_found
  end

  test "edit redirects non-admin to club page" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club, role: "member")

    get edit_club_path(club)
    assert_redirected_to club_path(club)
  end

  test "edit shows settings form for admin" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club, role: "admin")

    get edit_club_path(club)
    assert_response :success
    assert_select "form"
    assert_select "input[name='club[name]']"
  end

  test "update changes club attributes" do
    sign_in_as(@user)
    club = create(:club, name: "Old Name")
    create(:membership, user: @user, club: club, role: "admin")

    patch club_path(club), params: { club: { name: "New Name", description: "Updated description" } }

    assert_redirected_to club_path(club)
    club.reload
    assert_equal "New Name", club.name
    assert_equal "Updated description", club.description
  end

  test "update fails for non-admin" do
    sign_in_as(@user)
    club = create(:club, name: "Old Name")
    create(:membership, user: @user, club: club, role: "member")

    patch club_path(club), params: { club: { name: "New Name" } }

    assert_redirected_to club_path(club)
    assert_equal "Old Name", club.reload.name
  end

  test "update renders form with errors for invalid params" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club, role: "admin")

    patch club_path(club), params: { club: { name: "" } }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "destroy soft deletes club" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club, role: "admin")

    assert_no_difference("Club.count") do
      delete club_path(club)
    end

    assert club.reload.soft_deleted?
    assert_redirected_to dashboard_path
  end

  test "destroy fails for non-admin" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club, role: "member")

    delete club_path(club)

    assert_redirected_to club_path(club)
    assert_not club.reload.soft_deleted?
  end

  test "show displays meetings card with count for members" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club)
    create(:meeting, club: club, scheduled_at: 1.week.from_now)
    create(:meeting, club: club, scheduled_at: 2.weeks.from_now)

    get club_path(club)

    assert_response :success
    assert_select "a[href='#{club_meetings_path(club)}']"
  end

  test "show displays pulse indicator when meeting within 24 hours" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club)
    create(:meeting, club: club, scheduled_at: 12.hours.from_now)

    get club_path(club)

    assert_response :success
    assert_select ".animate-pulse"
  end

  test "show does not display pulse when no meeting within 24 hours" do
    sign_in_as(@user)
    club = create(:club)
    create(:membership, user: @user, club: club)
    create(:meeting, club: club, scheduled_at: 2.days.from_now)

    get club_path(club)

    assert_response :success
    assert_select ".animate-pulse", count: 0
  end
end
