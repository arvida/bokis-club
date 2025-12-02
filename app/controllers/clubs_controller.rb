class ClubsController < ApplicationController
  before_action :require_user!

  def new
    @club = Club.new
  end

  def create
    @club = Club.new(club_params)

    if @club.save
      @club.memberships.create!(user: current_user, role: "admin")
      redirect_to club_path(@club), notice: t("flash.clubs.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @club = Club.active.find(params[:id])
    @membership = current_user.memberships.find_by(club: @club)
    @is_admin = @club.admin?(current_user)
    @is_member = @club.member?(current_user)
    @suggestions_count = @club.suggested_books.count
    @voting_books = @club.voting_books.includes(:book, :votes)
    @voting_active = @voting_books.any?
    @next_club_book = @club.club_books.next_up.includes(:book).first

    upcoming_meetings = @club.meetings.upcoming
    @upcoming_meetings_count = upcoming_meetings.count
    @meeting_soon = upcoming_meetings.where(scheduled_at: ..24.hours.from_now).exists?

    if @voting_active && @is_member
      @user_vote = Vote.joins(:club_book)
                       .includes(club_book: :book)
                       .where(user: current_user)
                       .where(club_books: { club_id: @club.id, status: "voting" })
                       .first
    end
  end

  def edit
    @club = Club.active.find(params[:id])
    redirect_to club_path(@club), alert: t("flash.members.not_admin") unless @club.admin?(current_user)
  end

  def update
    @club = Club.active.find(params[:id])
    return redirect_to club_path(@club), alert: t("flash.members.not_admin") unless @club.admin?(current_user)

    if @club.update(club_params)
      redirect_to club_path(@club), notice: t("flash.clubs.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @club = Club.active.find(params[:id])
    return redirect_to club_path(@club), alert: t("flash.members.not_admin") unless @club.admin?(current_user)

    @club.soft_delete!
    redirect_to dashboard_path, notice: t("flash.clubs.deleted")
  end

  def leave
    @club = Club.active.find(params[:id])
    membership = current_user.memberships.find_by(club: @club)

    return redirect_to club_path(@club), alert: t("flash.members.not_member") unless membership

    if membership.admin? && @club.memberships.admins.count == 1
      return redirect_to club_members_path(@club), alert: t("flash.clubs.cannot_leave_last_admin")
    end

    membership.soft_delete!
    redirect_to dashboard_path, notice: t("flash.clubs.left", club: @club.name)
  end

  def regenerate_invite
    @club = Club.active.find(params[:id])
    return redirect_to club_path(@club), alert: t("flash.members.not_admin") unless @club.admin?(current_user)

    @club.regenerate_invite_code!
    redirect_to club_members_path(@club), notice: t("flash.clubs.invite_regenerated")
  end

  def join
    @club = Club.active.find(params[:id])

    if @club.member?(current_user)
      return redirect_to club_path(@club), notice: t("flash.invites.already_member")
    end

    if @club.privacy != "open"
      return redirect_to club_path(@club), alert: t("flash.clubs.not_open")
    end

    @club.memberships.create!(user: current_user, role: "member")
    redirect_to club_path(@club), notice: t("flash.clubs.joined", club: @club.name)
  rescue ActiveRecord::RecordNotUnique
    redirect_to club_path(@club), notice: t("flash.invites.already_member")
  end

  private

  def club_params
    params.require(:club).permit(:name, :description, :privacy, :cover_library_id, :cover_image)
  end
end
