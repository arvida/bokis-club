class PagesController < ApplicationController
  def landing
    redirect_to dashboard_path if signed_in?
  end
end
