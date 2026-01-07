require "test_helper"
require "webmock/minitest"

class AzureGptClientTest < ActiveSupport::TestCase
  setup do
    @credentials = {
      openai_api_key: "test-api-key",
      openai_uri: "https://test.openai.azure.com/openai/deployments/gpt-5.1",
      api_version: "2025-04-01-preview"
    }
    @client = AzureGptClient.new(credentials: @credentials)
    @api_url = "https://test.openai.azure.com/openai/deployments/gpt-5.1/chat/completions?api-version=2025-04-01-preview"
  end

  test "chat makes POST request to Azure endpoint" do
    stub_request(:post, @api_url)
      .with(
        headers: { "api-key" => "test-api-key", "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: { choices: [ { message: { content: "Test response" } } ] }.to_json
      )

    result = @client.chat([ { role: "user", content: "Hello" } ])

    assert_equal "Test response", result
  end

  test "chat raises ApiError on failed request" do
    stub_request(:post, @api_url)
      .to_return(status: 500, body: "Internal Server Error")

    assert_raises(AzureGptClient::ApiError) do
      @client.chat([ { role: "user", content: "Hello" } ])
    end
  end

  test "chat raises ApiError when credentials not configured" do
    client = AzureGptClient.new(credentials: { openai_api_key: nil, openai_uri: nil, api_version: nil })

    assert_raises(AzureGptClient::ApiError) do
      client.chat([ { role: "user", content: "Hello" } ])
    end
  end

  test "chat passes max_completion_tokens to API" do
    stub_request(:post, @api_url)
      .with { |request|
        body = JSON.parse(request.body)
        body["max_completion_tokens"] == 500
      }
      .to_return(
        status: 200,
        body: { choices: [ { message: { content: "Response" } } ] }.to_json
      )

    result = @client.chat([ { role: "user", content: "Hello" } ], max_completion_tokens: 500)
    assert_equal "Response", result
  end
end
