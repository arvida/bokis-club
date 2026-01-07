class ApplicationController < ActionController::Base
  include Passwordless::ControllerHelpers

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :signed_in?

  private

  def current_user
    @current_user ||= authenticate_by_session(User)
  end

  def signed_in?
    current_user.present?
  end

  def require_user!
    return if current_user

    save_passwordless_redirect_location!(User)
    redirect_to login_path, flash: { notice: t("flash.login_required") }
  end
end
