class MembersController < ApplicationController
  before_action :require_user!
  before_action :set_club
  before_action :require_membership!

  def index
    @members = @club.memberships.includes(:user).order(:created_at)
    @is_admin = @club.admin?(current_user)
  end

  def destroy
    return redirect_with_alert(:not_admin) unless @club.admin?(current_user)

    membership = @club.memberships.find_by(user_id: params[:id])
    return redirect_with_alert(:not_found) unless membership
    return redirect_with_alert(:cannot_remove_admin) if membership.admin?

    membership.soft_delete!
    redirect_to club_members_path(@club), notice: t("flash.members.removed")
  end

  def promote
    return redirect_with_alert(:not_admin) unless @club.admin?(current_user)

    membership = @club.memberships.find_by(user_id: params[:id])
    return redirect_with_alert(:not_found) unless membership

    membership.update!(role: "admin")
    redirect_to club_members_path(@club), notice: t("flash.members.promoted")
  end

  private

  def set_club
    @club = Club.active.find(params[:club_id])
  end

  def require_membership!
    return if @club.member?(current_user)
    redirect_to club_path(@club), alert: t("flash.members.not_member")
  end

  def redirect_with_alert(key)
    redirect_to club_members_path(@club), alert: t("flash.members.#{key}")
  end
end
