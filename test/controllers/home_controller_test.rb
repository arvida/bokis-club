require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "dashboard redirects to login when not authenticated" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "dashboard shows page when authenticated" do
    user = create(:user)
    sign_in_as(user)

    get dashboard_path
    assert_response :success
  end

  test "dashboard shows user's clubs" do
    user = create(:user)
    club = create(:club, name: "Min Bokcirkel")
    create(:membership, user: user, club: club)
    sign_in_as(user)

    get dashboard_path
    assert_response :success
    assert_select "h3", text: "Min Bokcirkel"
  end

  test "dashboard shows empty state when no clubs" do
    user = create(:user)
    sign_in_as(user)

    get dashboard_path
    assert_response :success
    assert_select "p", text: I18n.t("home.dashboard.empty")
  end

  test "dashboard shows create button" do
    user = create(:user)
    sign_in_as(user)

    get dashboard_path
    assert_response :success
    assert_select "a[href='#{new_club_path}']"
  end

  test "dashboard does not show soft-deleted clubs" do
    user = create(:user)
    club = create(:club, name: "Deleted Club")
    create(:membership, user: user, club: club)
    club.soft_delete!
    sign_in_as(user)

    get dashboard_path
    assert_response :success
    assert_select "h3", text: "Deleted Club", count: 0
  end
end
