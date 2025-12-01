class HomeController < ApplicationController
  before_action :require_user!

  def dashboard
    @clubs = current_user.clubs.active.order(updated_at: :desc)
  end
end
