require "test_helper"

class MeetingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @member = create(:user)
    @non_member = create(:user)
    @club = create(:club)
    create(:membership, user: @admin, club: @club, role: "admin")
    create(:membership, user: @member, club: @club, role: "member")
    @meeting = create(:meeting, club: @club)
  end

  test "index requires authentication" do
    get club_meetings_path(@club)
    assert_redirected_to login_path
  end

  test "index requires membership" do
    sign_in_as(@non_member)
    get club_meetings_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "index shows meetings for members" do
    sign_in_as(@member)
    get club_meetings_path(@club)
    assert_response :success
  end

  test "show requires authentication" do
    get club_meeting_path(@club, @meeting)
    assert_redirected_to login_path
  end

  test "show requires membership" do
    sign_in_as(@non_member)
    get club_meeting_path(@club, @meeting)
    assert_redirected_to club_path(@club)
  end

  test "show renders meeting for member" do
    sign_in_as(@member)
    get club_meeting_path(@club, @meeting)
    assert_response :success
  end

  test "new requires admin" do
    sign_in_as(@member)
    get new_club_meeting_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "new renders form for admin" do
    sign_in_as(@admin)
    get new_club_meeting_path(@club)
    assert_response :success
  end

  test "create requires admin" do
    sign_in_as(@member)
    post club_meetings_path(@club), params: { meeting: { title: "Test", scheduled_at: 1.week.from_now } }
    assert_redirected_to club_path(@club)
  end

  test "create creates meeting and auto-RSVPs admin" do
    sign_in_as(@admin)
    assert_difference -> { Meeting.count } => 1, -> { Rsvp.count } => 1 do
      post club_meetings_path(@club), params: {
        meeting: {
          title: "Test Meeting",
          scheduled_at: 1.week.from_now,
          location_type: "tbd"
        }
      }
    end
    meeting = Meeting.last
    assert_redirected_to club_meeting_path(@club, meeting)
    assert_equal "yes", meeting.rsvp_for(@admin).response
  end

  test "edit requires admin" do
    sign_in_as(@member)
    get edit_club_meeting_path(@club, @meeting)
    assert_redirected_to club_path(@club)
  end

  test "update requires admin" do
    sign_in_as(@member)
    patch club_meeting_path(@club, @meeting), params: { meeting: { title: "Updated" } }
    assert_redirected_to club_path(@club)
  end

  test "update updates meeting" do
    sign_in_as(@admin)
    patch club_meeting_path(@club, @meeting), params: { meeting: { title: "Updated Title" } }
    assert_redirected_to club_meeting_path(@club, @meeting)
    assert_equal "Updated Title", @meeting.reload.title
  end

  test "destroy requires admin" do
    sign_in_as(@member)
    delete club_meeting_path(@club, @meeting)
    assert_redirected_to club_path(@club)
  end

  test "destroy soft deletes meeting" do
    sign_in_as(@admin)
    delete club_meeting_path(@club, @meeting)
    assert_redirected_to club_meetings_path(@club)
    assert_not_nil @meeting.reload.deleted_at
  end

  test "rsvp creates new RSVP for member" do
    sign_in_as(@member)
    assert_difference "Rsvp.count", 1 do
      post rsvp_club_meeting_path(@club, @meeting), params: { response: "yes" }
    end
    assert_equal "yes", @meeting.rsvp_for(@member).response
  end

  test "rsvp updates existing RSVP" do
    sign_in_as(@member)
    @meeting.rsvps.create!(user: @member, response: "yes")

    assert_no_difference "Rsvp.count" do
      post rsvp_club_meeting_path(@club, @meeting), params: { response: "no" }
    end
    assert_equal "no", @meeting.rsvp_for(@member).response
  end

  test "rsvp with invalid response shows error" do
    sign_in_as(@member)

    assert_no_difference "Rsvp.count" do
      post rsvp_club_meeting_path(@club, @meeting), params: { response: "invalid" }
    end
    assert_redirected_to club_meeting_path(@club, @meeting)
    assert_equal I18n.t("flash.meetings.invalid_response"), flash[:alert]
  end

  test "calendar returns ICS file" do
    sign_in_as(@member)
    get calendar_club_meeting_path(@club, @meeting)
    assert_response :success
    assert_equal "text/calendar; charset=utf-8", response.content_type
    assert response.body.include?("BEGIN:VCALENDAR")
    assert response.body.include?(@meeting.title)
  end
end
