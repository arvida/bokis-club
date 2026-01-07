class HomeController < ApplicationController
  before_action :require_user!

  def dashboard
    @clubs = current_user.clubs.active.order(updated_at: :desc)
  end

  def meetings
    club_ids = current_user.clubs.active.pluck(:id)
    @upcoming_meetings = Meeting.where(club_id: club_ids)
                                .upcoming
                                .includes(:club, :club_book)
                                .order(scheduled_at: :asc)
                                .limit(20)
    @past_meetings = Meeting.where(club_id: club_ids)
                            .past
                            .includes(:club, :club_book)
                            .order(scheduled_at: :desc)
                            .limit(10)
  end
end
