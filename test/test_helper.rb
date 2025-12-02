ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "passwordless/test_helpers"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include Factory Bot methods
    include FactoryBot::Syntax::Methods
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    passwordless_sign_in(user)
  end
end
