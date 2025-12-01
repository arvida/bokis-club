Passwordless.configure do |config|
  config.default_from_address = "hej@bokis.club"
  config.expires_at = -> { 30.days.from_now }
  config.timeout_at = -> { 20.minutes.from_now }
  config.parent_mailer = "ActionMailer::Base"
  config.restrict_token_reuse = true
  config.success_redirect_path = "/mina-klubbar"
  config.sign_out_redirect_path = "/logga-in"
end
