require "net/http"
require "openssl"
require "json"

class GoogleBooksService
  API_BASE_URL = "https://www.googleapis.com/books/v1/volumes"

  def initialize(api_key: nil)
    @api_key = api_key || ENV["GOOGLE_BOOKS_API_KEY"] || Rails.application.credentials.dig(:google_books, :api_key)
  end

  def search(query, max_results: 10)
    return [] if query.blank?
    return [] if @api_key.blank?

    cache_key = "google_books_search:#{query}:#{max_results}"

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      perform_search(query, max_results)
    end
  end

  def find(google_books_id)
    return nil if @api_key.blank?

    uri = URI("#{API_BASE_URL}/#{google_books_id}")
    uri.query = URI.encode_www_form(key: @api_key)

    response = http_get(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    parse_book(JSON.parse(response.body))
  rescue StandardError => e
    Rails.error.report(e, context: { google_books_id: google_books_id })
    nil
  end

  def find_or_create_book(google_books_id)
    existing = Book.find_by(google_books_id: google_books_id)
    return existing if existing

    book_data = find(google_books_id)
    return nil unless book_data

    Book.create!(book_data)
  rescue ActiveRecord::RecordInvalid => e
    Rails.error.report(e, context: { google_books_id: google_books_id, book_data: book_data })
    nil
  end

  private

  def perform_search(query, max_results)
    uri = URI(API_BASE_URL)
    uri.query = URI.encode_www_form(q: query, maxResults: max_results, key: @api_key)

    response = http_get(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    items = data["items"] || []
    items.map { |item| parse_book(item) }
  rescue StandardError => e
    Rails.error.report(e, context: { query: query, max_results: max_results })
    []
  end

  def parse_book(item)
    volume_info = item["volumeInfo"] || {}

    {
      google_books_id: item["id"],
      title: volume_info["title"] || "Okänd titel",
      authors: volume_info["authors"] || [],
      description: volume_info["description"],
      page_count: volume_info["pageCount"],
      cover_url: extract_cover_url(volume_info),
      isbn: extract_isbn(volume_info)
    }
  end

  def extract_cover_url(volume_info)
    image_links = volume_info["imageLinks"] || {}
    image_links["thumbnail"] || image_links["smallThumbnail"]
  end

  def extract_isbn(volume_info)
    identifiers = volume_info["industryIdentifiers"] || []
    isbn_13 = identifiers.find { |id| id["type"] == "ISBN_13" }
    isbn_10 = identifiers.find { |id| id["type"] == "ISBN_10" }
    (isbn_13 || isbn_10)&.dig("identifier")
  end

  def http_get(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    http.request(request)
  end
end
