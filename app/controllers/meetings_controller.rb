class MeetingsController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :require_membership!
  before_action :require_admin!, except: [ :index, :show, :rsvp, :calendar ]
  before_action :set_meeting, only: [ :show, :edit, :update, :destroy, :rsvp, :calendar ]

  def index
    @upcoming_meetings = @club.meetings.upcoming.includes(:rsvps)
    @past_meetings = @club.meetings.past.includes(:rsvps)
  end

  def show
    @user_rsvp = @meeting.rsvp_for(current_user)
  end

  def new
    @meeting = @club.meetings.new
    @meeting.title = default_title
    @meeting.scheduled_at = 2.weeks.from_now.change(hour: 18, min: 0)
    @meeting.club_book = @club.club_books.reading.first || @club.club_books.next_up.first
  end

  def create
    @meeting = @club.meetings.new(meeting_params)

    if @meeting.save
      @meeting.rsvps.create!(user: current_user, response: "yes")
      redirect_to club_meeting_path(@club, @meeting), notice: t("flash.meetings.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meeting.update(meeting_params)
      redirect_to club_meeting_path(@club, @meeting), notice: t("flash.meetings.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @meeting.soft_delete!
    redirect_to club_meetings_path(@club), notice: t("flash.meetings.deleted")
  end

  def rsvp
    response = params[:response]

    unless Rsvp::RESPONSES.include?(response)
      redirect_to club_meeting_path(@club, @meeting), alert: t("flash.meetings.invalid_response")
      return
    end

    existing_rsvp = @meeting.rsvp_for(current_user)

    if existing_rsvp
      existing_rsvp.update!(response: response)
    else
      @meeting.rsvps.create!(user: current_user, response: response)
    end

    respond_to do |format|
      format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.meetings.rsvp_updated") }
      format.turbo_stream
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to club_meeting_path(@club, @meeting), alert: e.message
  end

  def calendar
    send_data ics_content,
              type: "text/calendar; charset=utf-8",
              disposition: "attachment",
              filename: "bokis-traff-#{@meeting.scheduled_at.to_date}.ics"
  end

  private

  def set_club
    @club = Club.active.find(params[:club_id])
  end

  def set_meeting
    @meeting = @club.meetings.find(params[:id])
  end

  def require_membership!
    return if @club.member?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_member")
  end

  def require_admin!
    return if @club.admin?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_admin")
  end

  def meeting_params
    params.require(:meeting).permit(:title, :scheduled_at, :ends_at, :location_type, :location, :notes, :club_book_id)
  end

  def default_title
    if @club.current_book
      "Diskussion: #{@club.current_book.title}"
    else
      "Bokcirkelmöte"
    end
  end

  def ics_content
    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//Bokis//Bokis Club//SV
      METHOD:PUBLISH
      BEGIN:VEVENT
      UID:meeting-#{@meeting.id}@bokis.club
      DTSTAMP:#{format_ics_time(Time.current)}
      DTSTART:#{format_ics_time(@meeting.scheduled_at)}
      DTEND:#{format_ics_time(@meeting.ends_at || @meeting.scheduled_at + 2.hours)}
      SUMMARY:#{escape_ics(@meeting.title)}
      LOCATION:#{escape_ics(@meeting.location.to_s)}
      DESCRIPTION:#{escape_ics(ics_description)}
      END:VEVENT
      END:VCALENDAR
    ICS
  end

  def format_ics_time(time)
    time.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def escape_ics(text)
    text.to_s.gsub(/[,;\\]/) { |c| "\\#{c}" }.gsub("\n", "\\n")
  end

  def ics_description
    description = "Bokcirkel: #{@club.name}"
    description += "\\n\\nBok: #{@meeting.club_book.book.title}" if @meeting.club_book
    description
  end
end
