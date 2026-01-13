class MeetingsController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :require_membership!
  before_action :require_admin!, except: [ :index, :show, :rsvp, :calendar, :check_in ]
  before_action :set_meeting, only: [ :show, :edit, :update, :destroy, :rsvp, :calendar, :start, :end_meeting, :resume, :check_in ]

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
    @meeting.host = current_user
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

  def start
    if @meeting.start!
      redirect_to club_meeting_path(@club, @meeting), notice: t("flash.meetings.started")
    else
      redirect_to club_meeting_path(@club, @meeting), alert: t("flash.meetings.already_started")
    end
  end

  def end_meeting
    if @meeting.end!
      # TODO: Phase 5 - redirect to rating page when ratings are implemented
      # redirect_to new_club_club_book_rating_path(@club, @meeting.club_book) if @meeting.club_book
      redirect_to club_meeting_path(@club, @meeting), notice: t("flash.meetings.ended")
    else
      redirect_to club_meeting_path(@club, @meeting), alert: t("flash.meetings.not_live")
    end
  end

  def resume
    if @meeting.resume!
      redirect_to club_meeting_path(@club, @meeting), notice: t("flash.meetings.resumed")
    else
      redirect_to club_meeting_path(@club, @meeting), alert: t("flash.meetings.not_ended")
    end
  end

  def check_in
    rsvp = @meeting.rsvp_for(current_user)

    if rsvp&.check_in!
      respond_to do |format|
        format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.meetings.checked_in") }
        format.turbo_stream
      end
    else
      redirect_to club_meeting_path(@club, @meeting), alert: t("flash.meetings.check_in_failed")
    end
  end

  def generate_questions
    club_book = @club.club_books.find_by(id: params[:club_book_id])

    unless club_book&.book
      render json: { questions: [] }
      return
    end

    book = club_book.book
    existing_questions = Array(params[:existing_questions]).map(&:strip).reject(&:blank?)

    cached = book.discussion_questions.for_language(@club.language).fresh
    available = cached.where.not(text: existing_questions)

    if available.count < 1
      generator = DiscussionQuestionGenerator.new
      generator.regenerate_for_book(book, language: @club.language, count: 5)
      cached = book.discussion_questions.for_language(@club.language).fresh.reload
      available = cached.where.not(text: existing_questions)
    end

    question = available.random_sample(1).first
    render json: { questions: question ? [ question.text ] : [] }
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
    params.require(:meeting).permit(:title, :scheduled_at, :ends_at, :location_type, :location, :notes, :club_book_id, :host_id, initial_questions: [])
  end

  def default_title
    if @club.current_book
      "Diskussion: #{@club.current_book.title}"
    else
      "Bokklubbsmöte"
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
    description = "Bokklubb: #{@club.name}"
    description += "\\n\\nBok: #{@meeting.club_book.book.title}" if @meeting.club_book
    description
  end
end
