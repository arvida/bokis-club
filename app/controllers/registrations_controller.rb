class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    return head(:ok) if honeypot_triggered?

    @user = User.new(user_params)

    if @user.save
      session = Passwordless::Session.create!(authenticatable: @user)
      Passwordless::Mailer.sign_in(session).deliver_now
      redirect_to auth_sign_in_path(email: @user.email)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name)
  end

  def honeypot_triggered?
    params[:website].present?
  end
end
