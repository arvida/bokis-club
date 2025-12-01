class HomeController < ApplicationController
  before_action :require_user!

  def dashboard
  end
end
