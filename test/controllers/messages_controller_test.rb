require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = create(:club)
    @user = create(:user)
    @membership = create(:membership, user: @user, club: @club)
  end

  test "index requires authentication" do
    get club_messages_path(@club)
    assert_redirected_to login_path
  end

  test "index requires membership" do
    other_user = create(:user)
    sign_in_as(other_user)

    get club_messages_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "index shows messages" do
    sign_in_as(@user)
    message = create(:message, club: @club, user: @user)

    get club_messages_path(@club)
    assert_response :success
    assert_match message.content, response.body
  end

  test "create requires authentication" do
    post club_messages_path(@club), params: { message: { content: "Test" } }
    assert_redirected_to login_path
  end

  test "create requires membership" do
    other_user = create(:user)
    sign_in_as(other_user)

    post club_messages_path(@club), params: { message: { content: "Test" } }
    assert_redirected_to club_path(@club)
  end

  test "create saves message" do
    sign_in_as(@user)

    assert_difference "Message.count", 1 do
      post club_messages_path(@club), params: { message: { content: "Hej alla!" } }
    end

    message = Message.last
    assert_equal "Hej alla!", message.content
    assert_equal @user, message.user
    assert_equal @club, message.club
  end

  test "create responds with turbo_stream" do
    sign_in_as(@user)

    post club_messages_path(@club),
      params: { message: { content: "Test meddelande" } },
      as: :turbo_stream

    assert_response :success
  end

  test "update requires authentication" do
    message = create(:message, club: @club, user: @user)
    patch club_message_path(@club, message), params: { message: { content: "Uppdaterad" } }
    assert_redirected_to login_path
  end

  test "update requires author" do
    author = create(:user)
    create(:membership, user: author, club: @club)
    message = create(:message, club: @club, user: author)

    sign_in_as(@user)
    patch club_message_path(@club, message), params: { message: { content: "Uppdaterad" } }
    assert_redirected_to club_messages_path(@club)
  end

  test "update within edit window" do
    sign_in_as(@user)
    message = create(:message, club: @club, user: @user)

    patch club_message_path(@club, message), params: { message: { content: "Uppdaterad" } }

    message.reload
    assert_equal "Uppdaterad", message.content
    assert message.edited?
  end

  test "update after edit window fails" do
    sign_in_as(@user)
    message = create(:message, club: @club, user: @user, created_at: 20.minutes.ago)

    patch club_message_path(@club, message), params: { message: { content: "Uppdaterad" } }
    assert_redirected_to club_messages_path(@club)

    message.reload
    assert_not_equal "Uppdaterad", message.content
  end

  test "destroy requires authentication" do
    message = create(:message, club: @club, user: @user)
    delete club_message_path(@club, message)
    assert_redirected_to login_path
  end

  test "destroy by author" do
    sign_in_as(@user)
    message = create(:message, club: @club, user: @user)

    assert_difference "Message.count", -1 do
      delete club_message_path(@club, message)
    end
  end

  test "destroy by admin" do
    admin = create(:user)
    create(:membership, user: admin, club: @club, role: "admin")
    message = create(:message, club: @club, user: @user)

    sign_in_as(admin)

    assert_difference "Message.count", -1 do
      delete club_message_path(@club, message)
    end
  end

  test "destroy by non-admin member fails" do
    other_member = create(:user)
    create(:membership, user: other_member, club: @club, role: "member")
    message = create(:message, club: @club, user: @user)

    sign_in_as(other_member)

    assert_no_difference "Message.count" do
      delete club_message_path(@club, message)
    end
    assert_redirected_to club_messages_path(@club)
  end
end
