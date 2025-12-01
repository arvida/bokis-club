require "test_helper"

class HoneypotTest < ActionDispatch::IntegrationTest
  test "login form rejects submission when honeypot is filled" do
    user = create(:user)

    post sign_in_path(authenticatable: "user"), params: {
      passwordless: { email: user.email },
      website: "http://spam.com"
    }

    assert_response :ok
    assert_equal 0, Passwordless::Session.count
  end

  test "login form allows submission when honeypot is empty" do
    user = create(:user)

    post sign_in_path(authenticatable: "user"), params: {
      passwordless: { email: user.email }
    }

    assert_response :redirect
    assert_equal 1, Passwordless::Session.count
  end

  test "login form has honeypot field" do
    get login_path
    assert_response :success
    assert_select "input[name='website']"
  end
end
