require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  setup do
    Rails.application.routes.default_url_options[:host] = "127.0.0.1"
  end
end
