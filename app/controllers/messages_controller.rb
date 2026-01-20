class MessagesController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :require_membership!
  before_action :set_message, only: [ :update, :destroy ]
  before_action :require_editable!, only: [ :update ]
  before_action :require_destroyable!, only: [ :destroy ]

  def index
    @messages = @club.messages.includes(:user, replies: :user).order(created_at: :desc)
    @message = @club.messages.new
  end

  def create
    @message = @club.messages.new(message_params)
    @message.user = current_user

    if @message.save
      respond_to do |format|
        format.html { redirect_to club_messages_path(@club), notice: t("flash.messages.created") }
        format.turbo_stream
      end
    else
      redirect_to club_messages_path(@club), alert: @message.errors.full_messages.first
    end
  end

  def update
    @message.edited_at = Time.current
    if @message.update(message_params)
      respond_to do |format|
        format.html { redirect_to club_messages_path(@club), notice: t("flash.messages.updated") }
        format.turbo_stream
      end
    else
      redirect_to club_messages_path(@club), alert: @message.errors.full_messages.first
    end
  end

  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to club_messages_path(@club), notice: t("flash.messages.deleted") }
      format.turbo_stream
    end
  end

  private

  def set_club
    @club = Club.active.find(params[:club_id])
  end

  def set_message
    @message = @club.messages.find(params[:id])
  end

  def require_membership!
    return if @club.member?(current_user)

    redirect_to club_path(@club), alert: t("flash.members.not_member")
  end

  def require_editable!
    return if @message.editable_by?(current_user)

    redirect_to club_messages_path(@club), alert: t("flash.messages.not_editable")
  end

  def require_destroyable!
    return if @message.destroyable_by?(current_user)

    redirect_to club_messages_path(@club), alert: t("flash.messages.not_authorized")
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
