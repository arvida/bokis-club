class DiscussionGuideItemsController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :set_meeting
  before_action :require_membership!
  before_action :require_admin!, except: [ :toggle ]
  before_action :set_discussion_guide

  def create
    text = params[:text].to_s.strip
    if text.present?
      @new_item = @discussion_guide.add_item(text, source: "user_added")
      respond_to do |format|
        format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.discussion_guide.item_added") }
        format.turbo_stream
      end
    else
      redirect_to club_meeting_path(@club, @meeting), alert: t("errors.messages.blank")
    end
  end

  def update
    item = @discussion_guide.find_item(params[:id])
    return redirect_to club_meeting_path(@club, @meeting), alert: "Item not found" unless item

    text = params[:text].to_s.strip
    if text.present?
      updated_items = @discussion_guide.items.map do |i|
        i["id"] == params[:id] ? i.merge("text" => text) : i
      end
      @discussion_guide.update!(items: updated_items)

      respond_to do |format|
        format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.discussion_guide.item_updated") }
        format.turbo_stream
      end
    else
      redirect_to club_meeting_path(@club, @meeting), alert: t("errors.messages.blank")
    end
  end

  def destroy
    @deleted_item_id = params[:id]
    @discussion_guide.remove_item(params[:id])
    respond_to do |format|
      format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.discussion_guide.item_deleted") }
      format.turbo_stream
    end
  end

  def toggle
    if @discussion_guide.toggle_item(params[:id])
      @toggled_item = @discussion_guide.find_item(params[:id])
      respond_to do |format|
        format.html { redirect_to club_meeting_path(@club, @meeting) }
        format.turbo_stream
      end
    else
      redirect_to club_meeting_path(@club, @meeting), alert: "Item not found"
    end
  end

  def regenerate
    unless @meeting.can_regenerate?
      redirect_to club_meeting_path(@club, @meeting), alert: t("flash.discussion_guide.max_regenerate")
      return
    end

    return unless @meeting.club_book&.book

    @meeting.increment_regenerate!
    book = @meeting.club_book.book
    language = @club.language

    generator = DiscussionQuestionGenerator.new
    questions = generator.regenerate_for_book(book, language: language)

    @new_items = questions.map do |question|
      @discussion_guide.add_item(question.text, source: "ai_generated")
    end

    respond_to do |format|
      format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.discussion_guide.regenerated") }
      format.turbo_stream
    end
  end

  private

  def set_club
    @club = Club.active.find(params[:club_id])
  end

  def set_meeting
    @meeting = @club.meetings.find(params[:meeting_id])
  end

  def set_discussion_guide
    @discussion_guide = @meeting.discussion_guide || @meeting.create_discussion_guide!
  end

  def require_membership!
    return if @club.member?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_member")
  end

  def require_admin!
    return if @club.admin?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_admin")
  end
end
