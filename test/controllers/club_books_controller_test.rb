require "test_helper"

class ClubBooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @member = create(:user)
    @club = create(:club)
    create(:membership, user: @admin, club: @club, role: "admin")
    create(:membership, user: @member, club: @club, role: "member")
    @book = create(:book)
  end

  test "new redirects to login when not authenticated" do
    get new_club_club_book_path(@club)
    assert_redirected_to login_path
  end

  test "new redirects non-admin to club page" do
    sign_in_as(@member)
    get new_club_club_book_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "new shows book search for admin" do
    sign_in_as(@admin)
    get new_club_club_book_path(@club)
    assert_response :success
    assert_select "[data-controller='book-search']"
  end

  test "create redirects non-admin" do
    sign_in_as(@member)
    post club_club_books_path(@club), params: { google_books_id: "abc123" }
    assert_redirected_to club_path(@club)
  end

  test "create with google_books_id creates club_book" do
    sign_in_as(@admin)
    stub_successful_find

    assert_difference("ClubBook.count", 1) do
      post club_club_books_path(@club), params: { google_books_id: "abc123" }
    end

    club_book = ClubBook.last
    assert_equal "reading", club_book.status
    assert_redirected_to club_path(@club)
  end

  test "create with manual entry creates book and club_book" do
    sign_in_as(@admin)

    assert_difference([ "Book.count", "ClubBook.count" ], 1) do
      post club_club_books_path(@club), params: {
        book: { title: "Min Bok", authors_string: "Anna, Erik", page_count: 200 }
      }
    end

    book = Book.last
    assert_equal "Min Bok", book.title
    assert_equal [ "Anna", "Erik" ], book.authors
    assert book.manual_entry?
  end

  test "create marks previous reading book as completed" do
    sign_in_as(@admin)
    previous_book = create(:book)
    previous_club_book = create(:club_book, club: @club, book: previous_book, status: "reading")
    stub_successful_find

    post club_club_books_path(@club), params: { google_books_id: "abc123" }

    previous_club_book.reload
    assert_equal "completed", previous_club_book.status
    assert_not_nil previous_club_book.completed_at
  end

  test "create with queue_next sets status to next" do
    sign_in_as(@admin)
    stub_successful_find

    post club_club_books_path(@club), params: { google_books_id: "abc123", queue_next: "1" }

    club_book = ClubBook.last
    assert_equal "next", club_book.status
    assert_redirected_to club_path(@club)
  end

  test "create with queue_next does not complete current book" do
    sign_in_as(@admin)
    current_book = create(:book)
    current_club_book = create(:club_book, club: @club, book: current_book, status: "reading")
    stub_successful_find

    post club_club_books_path(@club), params: { google_books_id: "abc123", queue_next: "1" }

    current_club_book.reload
    assert_equal "reading", current_club_book.status
    assert_nil current_club_book.completed_at
  end

  test "set_reading changes status to reading" do
    sign_in_as(@admin)
    club_book = create(:club_book, club: @club, book: @book, status: "suggested")

    patch set_reading_club_club_book_path(@club, club_book)

    club_book.reload
    assert_equal "reading", club_book.status
    assert_redirected_to club_path(@club)
  end

  test "set_reading marks previous reading book as completed" do
    sign_in_as(@admin)
    previous_book = create(:book)
    previous_club_book = create(:club_book, club: @club, book: previous_book, status: "reading")
    club_book = create(:club_book, club: @club, book: @book, status: "suggested")

    patch set_reading_club_club_book_path(@club, club_book)

    previous_club_book.reload
    assert_equal "completed", previous_club_book.status
  end

  test "destroy removes club_book" do
    sign_in_as(@admin)
    club_book = create(:club_book, club: @club, book: @book)

    assert_no_difference("ClubBook.count") do
      delete club_club_book_path(@club, club_book)
    end

    club_book.reload
    assert club_book.soft_deleted?
  end

  # Suggestion tests
  test "suggest_new shows form for member" do
    sign_in_as(@member)
    get suggest_club_club_books_path(@club)
    assert_response :success
    assert_select "[data-controller='book-search']"
  end

  test "suggest_new redirects non-member" do
    other_user = create(:user)
    sign_in_as(other_user)
    get suggest_club_club_books_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "suggest creates club_book with suggested status" do
    sign_in_as(@member)
    stub_successful_find

    assert_difference("ClubBook.count", 1) do
      post suggest_club_club_books_path(@club), params: {
        google_books_id: "abc123",
        notes: "This looks great!"
      }
    end

    club_book = ClubBook.last
    assert_equal "suggested", club_book.status
    assert_equal @member, club_book.suggested_by
    assert_equal "This looks great!", club_book.notes
    assert_redirected_to club_club_books_path(@club)
  end

  test "suggest with manual entry creates book" do
    sign_in_as(@member)

    assert_difference([ "Book.count", "ClubBook.count" ], 1) do
      post suggest_club_club_books_path(@club), params: {
        book: { title: "Manuell Bok" },
        notes: "Vill läsa denna"
      }
    end

    book = Book.last
    assert book.manual_entry?
    assert_equal "suggested", ClubBook.last.status
  end

  # Start voting tests
  test "start_voting redirects non-admin" do
    sign_in_as(@member)
    post start_voting_club_club_books_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "start_voting changes suggested books to voting status" do
    sign_in_as(@admin)
    book1 = create(:book)
    book2 = create(:book)
    club_book1 = create(:club_book, club: @club, book: book1, status: "suggested")
    club_book2 = create(:club_book, club: @club, book: book2, status: "suggested")

    post start_voting_club_club_books_path(@club)

    club_book1.reload
    club_book2.reload
    assert_equal "voting", club_book1.status
    assert_equal "voting", club_book2.status
    assert_redirected_to vote_club_club_books_path(@club)
  end

  test "start_voting requires at least 2 suggestions" do
    sign_in_as(@admin)
    create(:club_book, club: @club, book: @book, status: "suggested")

    post start_voting_club_club_books_path(@club)

    assert_redirected_to club_club_books_path(@club)
  end

  test "start_voting blocked when next book exists" do
    sign_in_as(@admin)
    create(:club_book, club: @club, book: @book, status: "next")
    book1 = create(:book)
    book2 = create(:book)
    create(:club_book, club: @club, book: book1, status: "suggested")
    create(:club_book, club: @club, book: book2, status: "suggested")

    post start_voting_club_club_books_path(@club)

    assert_redirected_to club_path(@club)
    assert_equal I18n.t("flash.club_books.has_next_book"), flash[:alert]
  end

  test "start_voting sets voting_deadline from params" do
    sign_in_as(@admin)
    book1 = create(:book)
    book2 = create(:book)
    create(:club_book, club: @club, book: book1, status: "suggested")
    create(:club_book, club: @club, book: book2, status: "suggested")

    deadline = 3.days.from_now.beginning_of_day
    post start_voting_club_club_books_path(@club), params: { voting_deadline: deadline.iso8601 }

    @club.reload
    assert_in_delta deadline, @club.voting_deadline, 1.second
  end

  test "start_voting uses default 7 days when no deadline param" do
    sign_in_as(@admin)
    book1 = create(:book)
    book2 = create(:book)
    create(:club_book, club: @club, book: book1, status: "suggested")
    create(:club_book, club: @club, book: book2, status: "suggested")

    post start_voting_club_club_books_path(@club)

    @club.reload
    assert_not_nil @club.voting_deadline
    assert_in_delta 7.days.from_now, @club.voting_deadline, 1.minute
  end

  test "start_voting rejects past deadline" do
    sign_in_as(@admin)
    book1 = create(:book)
    book2 = create(:book)
    create(:club_book, club: @club, book: book1, status: "suggested")
    create(:club_book, club: @club, book: book2, status: "suggested")

    past_deadline = 1.day.ago
    post start_voting_club_club_books_path(@club), params: { voting_deadline: past_deadline.iso8601 }

    assert_redirected_to club_club_books_path(@club)
    assert_equal I18n.t("flash.club_books.deadline_must_be_future"), flash[:alert]
    @club.reload
    assert_nil @club.voting_deadline
  end

  test "start_voting rejects invalid deadline" do
    sign_in_as(@admin)
    book1 = create(:book)
    book2 = create(:book)
    create(:club_book, club: @club, book: book1, status: "suggested")
    create(:club_book, club: @club, book: book2, status: "suggested")

    post start_voting_club_club_books_path(@club), params: { voting_deadline: "not-a-date" }

    assert_redirected_to club_club_books_path(@club)
    assert_equal I18n.t("flash.club_books.invalid_deadline"), flash[:alert]
    @club.reload
    assert_nil @club.voting_deadline
  end

  # Voting page tests
  test "vote page shows voting books" do
    sign_in_as(@member)
    book1 = create(:book)
    book2 = create(:book)
    create(:club_book, club: @club, book: book1, status: "voting")
    create(:club_book, club: @club, book: book2, status: "voting")

    get vote_club_club_books_path(@club)

    assert_response :success
  end

  test "vote casts vote for member" do
    sign_in_as(@member)
    club_book = create(:club_book, club: @club, book: @book, status: "voting")

    assert_difference("Vote.count", 1) do
      post vote_club_club_books_path(@club), params: { club_book_id: club_book.id }
    end

    assert_equal @member, Vote.last.user
    assert_equal club_book, Vote.last.club_book
  end

  test "member can only vote once" do
    sign_in_as(@member)
    club_book1 = create(:club_book, club: @club, book: @book, status: "voting")
    book2 = create(:book)
    club_book2 = create(:club_book, club: @club, book: book2, status: "voting")
    create(:vote, user: @member, club_book: club_book1)

    assert_no_difference("Vote.count") do
      post vote_club_club_books_path(@club), params: { club_book_id: club_book2.id }
    end
  end

  test "vote is rejected after deadline" do
    sign_in_as(@member)
    @club.update!(voting_deadline: 1.hour.ago)
    club_book = create(:club_book, club: @club, book: @book, status: "voting")

    assert_no_difference("Vote.count") do
      post vote_club_club_books_path(@club), params: { club_book_id: club_book.id }
    end

    assert_redirected_to vote_club_club_books_path(@club)
    assert_equal I18n.t("flash.club_books.voting_deadline_passed"), flash[:alert]
  end

  test "vote is allowed before deadline" do
    sign_in_as(@member)
    @club.update!(voting_deadline: 1.day.from_now)
    club_book = create(:club_book, club: @club, book: @book, status: "voting")

    assert_difference("Vote.count", 1) do
      post vote_club_club_books_path(@club), params: { club_book_id: club_book.id }
    end
  end

  # End voting tests
  test "end_voting redirects non-admin" do
    sign_in_as(@member)
    post end_voting_club_club_books_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "end_voting selects winner with most votes" do
    sign_in_as(@admin)
    book1 = create(:book)
    book2 = create(:book)
    club_book1 = create(:club_book, club: @club, book: book1, status: "voting")
    club_book2 = create(:club_book, club: @club, book: book2, status: "voting")

    user1 = create(:user)
    user2 = create(:user)
    create(:vote, user: user1, club_book: club_book1)
    create(:vote, user: user2, club_book: club_book1)

    post end_voting_club_club_books_path(@club)

    club_book1.reload
    club_book2.reload
    assert_equal "next", club_book1.status
    assert_equal "suggested", club_book2.status
    assert_redirected_to club_path(@club)
  end

  test "end_voting deletes votes after selecting winner" do
    sign_in_as(@admin)
    book1 = create(:book)
    club_book1 = create(:club_book, club: @club, book: book1, status: "voting")
    user1 = create(:user)
    create(:vote, user: user1, club_book: club_book1)

    assert_difference("Vote.count", -1) do
      post end_voting_club_club_books_path(@club)
    end
  end

  test "end_voting clears voting_deadline" do
    sign_in_as(@admin)
    @club.update!(voting_deadline: 3.days.from_now)
    book1 = create(:book)
    create(:club_book, club: @club, book: book1, status: "voting")

    post end_voting_club_club_books_path(@club)

    @club.reload
    assert_nil @club.voting_deadline
  end

  test "end_voting handles tie by selecting one winner randomly" do
    sign_in_as(@admin)
    book1 = create(:book)
    book2 = create(:book)
    club_book1 = create(:club_book, club: @club, book: book1, status: "voting")
    club_book2 = create(:club_book, club: @club, book: book2, status: "voting")

    user1 = create(:user)
    user2 = create(:user)
    create(:vote, user: user1, club_book: club_book1)
    create(:vote, user: user2, club_book: club_book2)

    post end_voting_club_club_books_path(@club)

    club_book1.reload
    club_book2.reload

    statuses = [ club_book1.status, club_book2.status ].sort
    assert_equal [ "next", "suggested" ], statuses
  end

  # Archive tests
  test "archive shows completed books" do
    sign_in_as(@member)
    completed_book = create(:club_book, club: @club, book: @book, status: "completed", completed_at: 1.week.ago)

    get archive_club_club_books_path(@club)

    assert_response :success
  end

  test "archive redirects non-member" do
    other_user = create(:user)
    sign_in_as(other_user)

    get archive_club_club_books_path(@club)

    assert_redirected_to club_path(@club)
  end

  # Show tests
  test "show displays book details" do
    sign_in_as(@member)
    club_book = create(:club_book, club: @club, book: @book, status: "reading")

    get club_club_book_path(@club, club_book)

    assert_response :success
  end

  # Start next book tests
  test "start_next_book redirects non-admin" do
    sign_in_as(@member)
    create(:club_book, club: @club, book: @book, status: "next")
    post start_next_book_club_club_books_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "start_next_book starts the queued book" do
    sign_in_as(@admin)
    next_book = create(:club_book, club: @club, book: @book, status: "next")

    post start_next_book_club_club_books_path(@club)

    next_book.reload
    assert_equal "reading", next_book.status
    assert_redirected_to club_path(@club)
  end

  test "start_next_book completes current book first" do
    sign_in_as(@admin)
    current = create(:club_book, club: @club, book: create(:book), status: "reading")
    next_book = create(:club_book, club: @club, book: @book, status: "next")

    post start_next_book_club_club_books_path(@club)

    current.reload
    assert_equal "completed", current.status
  end

  test "start_next_book redirects if no next book" do
    sign_in_as(@admin)

    post start_next_book_club_club_books_path(@club)

    assert_redirected_to club_path(@club)
    assert_equal I18n.t("flash.club_books.no_next_book"), flash[:alert]
  end

  # Cancel next book tests
  test "cancel_next_book redirects non-admin" do
    sign_in_as(@member)
    create(:club_book, club: @club, book: @book, status: "next")
    delete cancel_next_book_club_club_books_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "cancel_next_book returns book to suggested" do
    sign_in_as(@admin)
    next_book = create(:club_book, club: @club, book: @book, status: "next")

    delete cancel_next_book_club_club_books_path(@club)

    next_book.reload
    assert_equal "suggested", next_book.status
    assert_redirected_to club_path(@club)
  end

  test "cancel_next_book redirects if no next book" do
    sign_in_as(@admin)

    delete cancel_next_book_club_club_books_path(@club)

    assert_redirected_to club_path(@club)
    assert_equal I18n.t("flash.club_books.no_next_book"), flash[:alert]
  end

  # Mark complete tests
  test "mark_complete redirects non-admin" do
    sign_in_as(@member)
    create(:club_book, club: @club, book: @book, status: "reading")
    post mark_complete_club_club_books_path(@club)
    assert_redirected_to club_path(@club)
  end

  test "mark_complete completes current book" do
    sign_in_as(@admin)
    current = create(:club_book, club: @club, book: @book, status: "reading")

    post mark_complete_club_club_books_path(@club)

    current.reload
    assert_equal "completed", current.status
    assert_redirected_to club_path(@club)
  end

  test "mark_complete redirects if no current book" do
    sign_in_as(@admin)

    post mark_complete_club_club_books_path(@club)

    assert_redirected_to club_path(@club)
    assert_equal I18n.t("flash.club_books.no_current_book"), flash[:alert]
  end

  private

  def stub_successful_find
    response_body = {
      id: "abc123",
      volumeInfo: {
        title: "Test Book Title",
        authors: [ "Test Author" ],
        description: "Test description",
        pageCount: 200,
        imageLinks: { thumbnail: "https://example.com/cover.jpg" }
      }
    }.to_json

    stub_request(:get, /www.googleapis.com\/books\/v1\/volumes\/abc123/)
      .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
  end
end
