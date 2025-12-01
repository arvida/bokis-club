require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "shows signup form" do
    get signup_path
    assert_response :success
    assert_select "h1", /Skapa konto/
    assert_select "input[name='user[name]']"
    assert_select "input[name='user[email]']"
  end

  test "creates user and sends magic link with valid data" do
    assert_difference "User.count", 1 do
      post signup_path, params: { user: { name: "Anna Svensson", email: "anna@example.com" } }
    end

    user = User.find_by(email: "anna@example.com")
    assert_equal "Anna Svensson", user.name
    assert_equal "sv", user.locale

    assert_redirected_to auth_sign_in_path(email: "anna@example.com")
  end

  test "rejects submission when honeypot is filled" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: { name: "Bot User", email: "bot@example.com" },
        website: "http://spam.com"
      }
    end

    assert_response :ok
  end

  test "shows errors for invalid data" do
    assert_no_difference "User.count" do
      post signup_path, params: { user: { name: "", email: "invalid" } }
    end

    assert_response :unprocessable_entity
  end

  test "shows error for existing email" do
    create(:user, email: "existing@example.com")

    assert_no_difference "User.count" do
      post signup_path, params: { user: { name: "Another User", email: "existing@example.com" } }
    end

    assert_response :unprocessable_entity
  end

  test "signup form has honeypot field" do
    get signup_path
    assert_response :success
    assert_select "input[name='website']"
  end
end
