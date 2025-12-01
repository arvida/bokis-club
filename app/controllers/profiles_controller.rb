class ProfilesController < ApplicationController
  before_action :require_user!

  def show
  end

  def update
    if current_user.update(user_params)
      redirect_to profile_path, notice: t("flash.profile.updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :locale, :avatar)
  end
end
