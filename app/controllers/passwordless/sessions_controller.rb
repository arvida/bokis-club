require "bcrypt"

module Passwordless
  class SessionsController < ApplicationController
    include Passwordless::ControllerHelpers

    helper_method :email_field

    def new
      @session = Passwordless::Session.new
    end

    def create
      return head(:ok) if params[:website].present?

      @resource = find_authenticatable
      unless @resource
        flash.alert = I18n.t("passwordless.sessions.create.not_found")
        return render(:new, status: :not_found)
      end

      @session = build_passwordless_session(@resource)

      if @session.save
        Passwordless.config.after_session_save.call(@session, request)
        redirect_to(
          Passwordless.context.path_for(@session, id: @session.to_param, action: "show"),
          flash: { notice: I18n.t("passwordless.sessions.create.email_sent", email: @resource.email) }
        )
      else
        flash.alert = I18n.t("passwordless.sessions.create.error")
        render(:new, status: :unprocessable_entity)
      end
    end

    def show
      @session = find_session
    end

    def update
      @session = find_session
      BCrypt::Password.create(passwordless_params[:token])
      authenticate_and_sign_in(@session, passwordless_params[:token])
    end

    def confirm
      return head(:ok) if request.head?
      @session = find_session
      BCrypt::Password.create(params[:token])
      authenticate_and_sign_in(@session, params[:token])
    end

    def destroy
      sign_out(User)
      redirect_to Passwordless.config.sign_out_redirect_path,
                  notice: I18n.t("passwordless.sessions.destroy.signed_out")
    end

    private

    def find_authenticatable
      User.find_by("lower(email) = ?", passwordless_params[:email].downcase.strip)
    end

    def find_session
      Passwordless::Session.find_by!(identifier: params[:id], authenticatable_type: "User")
    end

    def authenticate_and_sign_in(session, token)
      if session.authenticate(token)
        sign_in(session)
        cookies[:show_pwa_banner] = { value: "1", expires: 1.minute.from_now }
        redirect_to Passwordless.config.success_redirect_path, status: :see_other
      else
        flash.alert = I18n.t("passwordless.sessions.errors.invalid_token")
        render(status: :forbidden, action: "show")
      end
    rescue Passwordless::Errors::TokenAlreadyClaimedError
      flash.alert = I18n.t("passwordless.sessions.errors.token_claimed")
      redirect_to Passwordless.config.sign_out_redirect_path, status: :see_other
    rescue Passwordless::Errors::SessionTimedOutError
      flash.alert = I18n.t("passwordless.sessions.errors.session_expired")
      redirect_to Passwordless.config.sign_out_redirect_path, status: :see_other
    end

    def email_field
      :email
    end

    def passwordless_params
      params.require(:passwordless).permit(:email, :token)
    end
  end
end
