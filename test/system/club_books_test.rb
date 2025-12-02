require "application_system_test_case"

class ClubBooksTest < ApplicationSystemTestCase
  include Passwordless::TestHelpers

  setup do
    @admin = create(:user)
    @club = create(:club)
    create(:membership, user: @admin, club: @club, role: "admin")

    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes/)
      .to_return(status: 200, body: { items: [] }.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "admin can add a book manually and start reading" do
    passwordless_sign_in(@admin)

    visit new_club_club_book_path(@club)

    assert_selector "h1", text: "Välj bok att läsa"

    fill_in placeholder: "Sök efter bok...", with: "xyz123notfound"

    assert_text "Inga böcker hittades", wait: 5

    click_button "Kan du inte hitta boken? Lägg till manuellt"

    assert_selector "[data-book-search-target='manualEntry']:not(.hidden)", wait: 2

    fill_in "book[title]", with: "Min Testbok"
    fill_in "book[authors_string]", with: "Test Författare"
    fill_in "book[page_count]", with: "200"

    click_button "Börja läsa"

    assert_current_path club_path(@club)
    assert_text "Ni läser nu Min Testbok"

    book = Book.find_by(title: "Min Testbok")
    assert_not_nil book, "Book should have been created"
    assert_nil book.google_books_id
    assert_equal [ "Test Författare" ], book.authors
  end
end
