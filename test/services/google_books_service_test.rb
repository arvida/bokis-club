require "test_helper"

class GoogleBooksServiceTest < ActiveSupport::TestCase
  setup do
    @service = GoogleBooksService.new
  end

  test "search returns empty array for blank query" do
    assert_equal [], @service.search("")
    assert_equal [], @service.search(nil)
  end

  test "search returns array of book hashes" do
    stub_successful_search

    results = @service.search("harry potter")

    assert_kind_of Array, results
    assert results.length > 0
  end

  test "search results have required keys" do
    stub_successful_search

    results = @service.search("harry potter")
    book = results.first

    assert book.key?(:google_books_id)
    assert book.key?(:title)
    assert book.key?(:authors)
    assert book.key?(:description)
    assert book.key?(:page_count)
    assert book.key?(:cover_url)
    assert book.key?(:isbn)
  end

  test "search handles API errors gracefully" do
    stub_api_error

    results = @service.search("test query")

    assert_equal [], results
  end

  test "search handles missing API key gracefully" do
    service = GoogleBooksService.new(api_key: "")

    results = service.search("test query")

    assert_equal [], results
  end

  test "find returns book hash for valid id" do
    stub_successful_find

    result = @service.find("abc123")

    assert_not_nil result
    assert_equal "abc123", result[:google_books_id]
  end

  test "find returns nil for invalid id" do
    stub_not_found

    result = @service.find("invalid")

    assert_nil result
  end

  test "find_or_create_book returns existing book" do
    existing = create(:book, google_books_id: "existing123", title: "Existing Book")

    result = @service.find_or_create_book("existing123")

    assert_equal existing, result
  end

  test "find_or_create_book creates new book from API" do
    stub_successful_find

    assert_difference("Book.count", 1) do
      result = @service.find_or_create_book("abc123")

      assert_equal "abc123", result.google_books_id
      assert_equal "Test Book Title", result.title
    end
  end

  test "find_or_create_book returns nil when API fails" do
    stub_not_found

    result = @service.find_or_create_book("unknown")

    assert_nil result
  end

  private

  def stub_successful_search
    response_body = {
      items: [
        {
          id: "book123",
          volumeInfo: {
            title: "Harry Potter",
            authors: [ "J.K. Rowling" ],
            description: "A young wizard's journey",
            pageCount: 320,
            imageLinks: { thumbnail: "https://example.com/cover.jpg" },
            industryIdentifiers: [ { type: "ISBN_13", identifier: "9780123456789" } ]
          }
        }
      ]
    }.to_json

    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
  end

  def stub_successful_find
    response_body = {
      id: "abc123",
      volumeInfo: {
        title: "Test Book Title",
        authors: [ "Test Author" ],
        description: "Test description",
        pageCount: 200,
        imageLinks: { thumbnail: "https://example.com/cover.jpg" },
        industryIdentifiers: [ { type: "ISBN_13", identifier: "9780123456789" } ]
      }
    }.to_json

    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes\/abc123/)
      .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
  end

  def stub_api_error
    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 500, body: "Internal Server Error")
  end

  def stub_not_found
    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 404, body: { error: { code: 404 } }.to_json)
  end
end
