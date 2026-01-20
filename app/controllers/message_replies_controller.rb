class MessageRepliesController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :set_message
  before_action :require_membership!
  before_action :set_reply, only: [ :update, :destroy ]
  before_action :require_editable!, only: [ :update ]
  before_action :require_destroyable!, only: [ :destroy ]

  def create
    @reply = @message.replies.new(reply_params)
    @reply.user = current_user

    if @reply.save
      respond_to do |format|
        format.html { redirect_to club_messages_path(@club), notice: t("flash.messages.reply_created") }
        format.turbo_stream
      end
    else
      redirect_to club_messages_path(@club), alert: @reply.errors.full_messages.first
    end
  end

  def update
    @reply.edited_at = Time.current
    if @reply.update(reply_params)
      respond_to do |format|
        format.html { redirect_to club_messages_path(@club), notice: t("flash.messages.reply_updated") }
        format.turbo_stream
      end
    else
      redirect_to club_messages_path(@club), alert: @reply.errors.full_messages.first
    end
  end

  def destroy
    @reply.destroy
    respond_to do |format|
      format.html { redirect_to club_messages_path(@club), notice: t("flash.messages.reply_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_club
    @club = Club.active.find(params[:club_id])
  end

  def set_message
    @message = @club.messages.find(params[:message_id])
  end

  def set_reply
    @reply = @message.replies.find(params[:id])
  end

  def require_membership!
    return if @club.member?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_member")
  end

  def require_editable!
    return if @reply.editable_by?(current_user)

    redirect_to club_messages_path(@club), alert: t("flash.messages.not_editable")
  end

  def require_destroyable!
    return if @reply.destroyable_by?(current_user)

    redirect_to club_messages_path(@club), alert: t("flash.messages.not_authorized")
  end

  def reply_params
    params.require(:message_reply).permit(:content)
  end
end
