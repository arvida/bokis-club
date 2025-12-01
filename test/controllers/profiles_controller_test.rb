require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not authenticated" do
    get profile_path
    assert_redirected_to login_path
  end

  test "shows profile when authenticated" do
    user = create(:user)
    sign_in_as(user)

    get profile_path
    assert_response :success
    assert_match user.name, response.body
    assert_match user.email, response.body
  end

  test "updates name successfully" do
    user = create(:user, name: "Original Name")
    sign_in_as(user)

    patch profile_path, params: { user: { name: "New Name" } }
    assert_redirected_to profile_path

    user.reload
    assert_equal "New Name", user.name
  end

  test "updates locale successfully" do
    user = create(:user, locale: "sv")
    sign_in_as(user)

    patch profile_path, params: { user: { locale: "en" } }
    assert_redirected_to profile_path

    user.reload
    assert_equal "en", user.locale
  end

  test "shows validation errors for invalid name" do
    user = create(:user)
    sign_in_as(user)

    patch profile_path, params: { user: { name: "" } }
    assert_response :unprocessable_entity
  end
end
