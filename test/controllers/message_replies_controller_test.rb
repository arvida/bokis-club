require "test_helper"

class MessageRepliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @club = create(:club)
    @user = create(:user)
    @membership = create(:membership, user: @user, club: @club)
    @message = create(:message, club: @club, user: @user)
  end

  test "create requires authentication" do
    post club_message_replies_path(@club, @message), params: { message_reply: { content: "Test" } }
    assert_redirected_to login_path
  end

  test "create requires membership" do
    other_user = create(:user)
    sign_in_as(other_user)

    post club_message_replies_path(@club, @message), params: { message_reply: { content: "Test" } }
    assert_redirected_to club_path(@club)
  end

  test "create saves reply" do
    sign_in_as(@user)

    assert_difference "MessageReply.count", 1 do
      post club_message_replies_path(@club, @message), params: { message_reply: { content: "Ett svar!" } }
    end

    reply = MessageReply.last
    assert_equal "Ett svar!", reply.content
    assert_equal @user, reply.user
    assert_equal @message, reply.message
  end

  test "create responds with turbo_stream" do
    sign_in_as(@user)

    post club_message_replies_path(@club, @message),
      params: { message_reply: { content: "Test svar" } },
      as: :turbo_stream

    assert_response :success
  end

  test "update requires authentication" do
    reply = create(:message_reply, message: @message, user: @user)
    patch club_message_reply_path(@club, @message, reply), params: { message_reply: { content: "Uppdaterad" } }
    assert_redirected_to login_path
  end

  test "update requires author" do
    author = create(:user)
    create(:membership, user: author, club: @club)
    reply = create(:message_reply, message: @message, user: author)

    sign_in_as(@user)
    patch club_message_reply_path(@club, @message, reply), params: { message_reply: { content: "Uppdaterad" } }
    assert_redirected_to club_messages_path(@club)
  end

  test "update within edit window" do
    sign_in_as(@user)
    reply = create(:message_reply, message: @message, user: @user)

    patch club_message_reply_path(@club, @message, reply), params: { message_reply: { content: "Uppdaterad" } }

    reply.reload
    assert_equal "Uppdaterad", reply.content
    assert reply.edited?
  end

  test "update after edit window fails" do
    sign_in_as(@user)
    reply = create(:message_reply, message: @message, user: @user, created_at: 20.minutes.ago)

    patch club_message_reply_path(@club, @message, reply), params: { message_reply: { content: "Uppdaterad" } }
    assert_redirected_to club_messages_path(@club)

    reply.reload
    assert_not_equal "Uppdaterad", reply.content
  end

  test "destroy requires authentication" do
    reply = create(:message_reply, message: @message, user: @user)
    delete club_message_reply_path(@club, @message, reply)
    assert_redirected_to login_path
  end

  test "destroy by author" do
    sign_in_as(@user)
    reply = create(:message_reply, message: @message, user: @user)

    assert_difference "MessageReply.count", -1 do
      delete club_message_reply_path(@club, @message, reply)
    end
  end

  test "destroy by admin" do
    admin = create(:user)
    create(:membership, user: admin, club: @club, role: "admin")
    reply = create(:message_reply, message: @message, user: @user)

    sign_in_as(admin)

    assert_difference "MessageReply.count", -1 do
      delete club_message_reply_path(@club, @message, reply)
    end
  end

  test "destroy by non-admin member fails" do
    other_member = create(:user)
    create(:membership, user: other_member, club: @club, role: "member")
    reply = create(:message_reply, message: @message, user: @user)

    sign_in_as(other_member)

    assert_no_difference "MessageReply.count" do
      delete club_message_reply_path(@club, @message, reply)
    end
    assert_redirected_to club_messages_path(@club)
  end
end
