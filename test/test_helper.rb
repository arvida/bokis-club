ENV["RAILS_ENV"] ||= "test"
ENV["GOOGLE_BOOKS_API_KEY"] ||= "test_api_key"
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

    # Global stub for Azure OpenAI API (used by DiscussionQuestionGenerator)
    setup do
      stub_request(:post, /openai\.azure\.com.*chat\/completions/)
        .to_return(
          status: 200,
          body: { choices: [ { message: { content: "Testvfråga 1?\nTestfråga 2?" } } ] }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    passwordless_sign_in(user)
  end
end
