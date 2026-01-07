require "test_helper"

class InvitesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @club = create(:club)
  end

  test "show displays club info for valid invite" do
    sign_in_as(@user)
    get invite_path(@club.invite_code)

    assert_response :success
    assert_select "h1", text: @club.name
  end

  test "show displays club info for valid invite when not authenticated" do
    get invite_path(@club.invite_code)

    assert_response :success
    assert_select "h1", text: @club.name
    assert_select "a[href='#{login_path}']"
    assert_select "a[href='#{signup_path}']"
  end

  test "show displays error for invalid code" do
    sign_in_as(@user)
    get invite_path("invalid1")

    assert_response :not_found
  end

  test "show displays error for expired invite" do
    sign_in_as(@user)
    @club.update!(invite_expires_at: 1.day.ago)

    get invite_path(@club.invite_code)
    assert_response :gone
  end

  test "show displays error for used invite" do
    sign_in_as(@user)
    @club.update!(invite_used_at: 1.day.ago)

    get invite_path(@club.invite_code)
    assert_response :gone
  end

  test "show redirects to club if already member" do
    sign_in_as(@user)
    create(:membership, user: @user, club: @club)

    get invite_path(@club.invite_code)
    assert_redirected_to club_path(@club)
  end

  test "create joins club with valid code" do
    sign_in_as(@user)

    assert_difference("Membership.count", 1) do
      post invite_path(@club.invite_code)
    end

    membership = Membership.last
    assert_equal @user, membership.user
    assert_equal @club, membership.club
    assert_equal "member", membership.role
  end

  test "create marks invite as used" do
    sign_in_as(@user)
    assert_nil @club.invite_used_at

    post invite_path(@club.invite_code)

    @club.reload
    assert_not_nil @club.invite_used_at
  end

  test "create redirects to club on success" do
    sign_in_as(@user)
    post invite_path(@club.invite_code)

    assert_redirected_to club_path(@club)
  end

  test "create shows success flash" do
    sign_in_as(@user)
    post invite_path(@club.invite_code)

    assert_equal I18n.t("flash.invites.joined", club: @club.name), flash[:notice]
  end

  test "create fails for invalid code" do
    sign_in_as(@user)

    assert_no_difference("Membership.count") do
      post invite_path("invalid1")
    end

    assert_response :not_found
  end

  test "create fails for expired invite" do
    sign_in_as(@user)
    @club.update!(invite_expires_at: 1.day.ago)

    assert_no_difference("Membership.count") do
      post invite_path(@club.invite_code)
    end

    assert_response :gone
  end

  test "create does not duplicate membership" do
    sign_in_as(@user)
    create(:membership, user: @user, club: @club)

    assert_no_difference("Membership.count") do
      post invite_path(@club.invite_code)
    end

    assert_redirected_to club_path(@club)
  end

  test "create redirects to login when not authenticated" do
    post invite_path(@club.invite_code)
    assert_redirected_to login_path
  end
end
