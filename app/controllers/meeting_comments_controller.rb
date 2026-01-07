class MeetingCommentsController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :set_meeting
  before_action :require_membership!
  before_action :set_comment, only: [ :update, :destroy ]
  before_action :require_author!, only: [ :update, :destroy ]

  def create
    @comment = @meeting.comments.new(comment_params)
    @comment.user = current_user

    if @comment.save
      respond_to do |format|
        format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.comments.created") }
        format.turbo_stream
      end
    else
      redirect_to club_meeting_path(@club, @meeting), alert: @comment.errors.full_messages.first
    end
  end

  def update
    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.comments.updated") }
        format.turbo_stream
      end
    else
      redirect_to club_meeting_path(@club, @meeting), alert: @comment.errors.full_messages.first
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to club_meeting_path(@club, @meeting), notice: t("flash.comments.deleted") }
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

  def set_comment
    @comment = @meeting.comments.find(params[:id])
  end

  def require_membership!
    return if @club.member?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_member")
  end

  def require_author!
    return if @comment.editable_by?(current_user)

    redirect_to club_meeting_path(@club, @meeting), alert: t("flash.comments.not_authorized")
  end

  def comment_params
    params.require(:meeting_comment).permit(:content)
  end
end
