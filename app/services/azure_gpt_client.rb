require "net/http"
require "json"

class AzureGptClient
  class ApiError < StandardError; end

  def initialize(credentials: nil)
    creds = credentials || Rails.application.credentials.azure_gpt51 || {}
    @api_key = creds[:openai_api_key]
    @base_uri = creds[:openai_uri]
    @api_version = creds[:api_version]
  end

  def chat(messages, max_completion_tokens: 1000)
    raise ApiError, "Azure GPT credentials not configured" if @api_key.blank? || @base_uri.blank?

    uri = build_uri
    response = http_post(uri, {
      messages: messages,
      max_completion_tokens: max_completion_tokens
    })

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "Azure GPT API error: #{response.code} - #{response.body}"
    end

    parse_response(response.body)
  end

  private

  def build_uri
    uri = URI("#{@base_uri}/chat/completions")
    uri.query = URI.encode_www_form(
      "api-version" => @api_version
    )
    uri
  end

  def http_post(uri, body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["api-key"] = @api_key
    request.body = body.to_json

    http.request(request)
  end

  def parse_response(body)
    data = JSON.parse(body)
    data.dig("choices", 0, "message", "content")
  end
end
