require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "login page renders successfully" do
    get login_path
    assert_response :success
  end

  test "dashboard redirects to login when not authenticated" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "dashboard is accessible when authenticated" do
    user = create(:user)
    sign_in_as(user)

    get dashboard_path
    assert_response :success
    assert_match user.name, response.body
  end

  test "requesting magic link for existing email sends email" do
    user = create(:user, email: "existing@example.com")

    assert_difference "Passwordless::Session.count", 1 do
      post auth_sign_in_path, params: {
        passwordless: { email: "existing@example.com" }
      }
    end
  end
end
