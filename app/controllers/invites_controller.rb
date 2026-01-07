class InvitesController < ApplicationController
  before_action :set_club_by_invite_code
  before_action :check_invite_validity
  before_action :require_user!, only: :create

  def show
    if signed_in?
      redirect_to club_path(@club) if already_member?
    end
  end

  def create
    return redirect_to club_path(@club), notice: t("flash.invites.already_member") if already_member?

    @club.memberships.create!(user: current_user, role: "member")
    @club.mark_invite_used!
    redirect_to club_path(@club), notice: t("flash.invites.joined", club: @club.name)
  rescue ActiveRecord::RecordNotUnique
    redirect_to club_path(@club), notice: t("flash.invites.already_member")
  end

  private

  def set_club_by_invite_code
    code = params[:code].to_s.downcase
    @club = Club.active.find_by(invite_code: code)
    render_not_found unless @club
  end

  def check_invite_validity
    return unless @club
    render_invite_invalid unless @club.invite_valid?
  end

  def already_member?
    @club.member?(current_user)
  end

  def render_not_found
    render "not_found", status: :not_found
  end

  def render_invite_invalid
    render "invalid", status: :gone
  end
end
