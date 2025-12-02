require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @club = create(:club)
    create(:membership, user: @user, club: @club, role: "admin")
  end

  test "search redirects to login when not authenticated" do
    get search_books_path
    assert_redirected_to login_path
  end

  test "search returns success when authenticated" do
    sign_in_as(@user)
    stub_empty_search

    get search_books_path, params: { q: "test" }

    assert_response :success
  end

  test "search returns empty results for blank query" do
    sign_in_as(@user)

    get search_books_path, params: { q: "" }

    assert_response :success
    assert_select "[data-testid='no-results']"
  end

  test "search returns results for valid query" do
    sign_in_as(@user)
    stub_successful_search

    get search_books_path, params: { q: "harry potter" }

    assert_response :success
    assert_select "[data-testid='book-result']", count: 1
  end

  test "search is turbo frame response" do
    sign_in_as(@user)
    stub_successful_search

    get search_books_path, params: { q: "test" }, headers: { "Turbo-Frame" => "book-search-results" }

    assert_response :success
  end

  private

  def stub_empty_search
    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 200, body: { items: [] }.to_json, headers: { "Content-Type" => "application/json" })
  end

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
            imageLinks: { thumbnail: "https://example.com/cover.jpg" }
          }
        }
      ]
    }.to_json

    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
  end
end
