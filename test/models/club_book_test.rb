require "test_helper"

class ClubBookTest < ActiveSupport::TestCase
  test "valid club_book with required attributes" do
    club_book = build(:club_book)
    assert club_book.valid?
  end

  test "club is required" do
    club_book = build(:club_book, club: nil)
    assert_not club_book.valid?
  end

  test "book is required" do
    club_book = build(:club_book, book: nil)
    assert_not club_book.valid?
  end

  test "status defaults to suggested" do
    club_book = ClubBook.new
    assert_equal "suggested", club_book.status
  end

  test "status must be valid" do
    club_book = build(:club_book, status: "invalid")
    assert_not club_book.valid?
    assert_includes club_book.errors[:status], "finns inte i listan"
  end

  test "status can be suggested" do
    club_book = build(:club_book, status: "suggested")
    assert club_book.valid?
  end

  test "status can be voting" do
    club_book = build(:club_book, status: "voting")
    assert club_book.valid?
  end

  test "status can be reading" do
    club_book = build(:club_book, status: "reading")
    assert club_book.valid?
  end

  test "status can be completed" do
    club_book = build(:club_book, status: "completed")
    assert club_book.valid?
  end

  test "club and book combination must be unique" do
    club = create(:club)
    book = create(:book)
    create(:club_book, club: club, book: book)

    duplicate = build(:club_book, club: club, book: book)
    assert_not duplicate.valid?
  end

  test "same book can be in different clubs" do
    book = create(:book)
    club1 = create(:club)
    club2 = create(:club)

    create(:club_book, club: club1, book: book)
    club_book2 = build(:club_book, club: club2, book: book)

    assert club_book2.valid?
  end

  test "suggested_by is optional" do
    club_book = build(:club_book, suggested_by: nil)
    assert club_book.valid?
  end

  test "notes is optional" do
    club_book = build(:club_book, notes: nil)
    assert club_book.valid?
  end

  test "deleted_at defaults to nil" do
    club_book = create(:club_book)
    assert_nil club_book.deleted_at
  end

  test "soft_deleted? returns false when deleted_at is nil" do
    club_book = build(:club_book, deleted_at: nil)
    assert_not club_book.soft_deleted?
  end

  test "soft_deleted? returns true when deleted_at is present" do
    club_book = build(:club_book, deleted_at: Time.current)
    assert club_book.soft_deleted?
  end

  test "soft_delete! sets deleted_at" do
    club_book = create(:club_book)
    club_book.soft_delete!
    assert club_book.soft_deleted?
  end

  test "active scope excludes soft deleted" do
    active = create(:club_book)
    deleted = create(:club_book)
    deleted.soft_delete!

    assert_includes ClubBook.active, active
    assert_not_includes ClubBook.active, deleted
  end

  test "reading scope returns books with reading status" do
    reading = create(:club_book, status: "reading")
    suggested = create(:club_book, status: "suggested")

    assert_includes ClubBook.reading, reading
    assert_not_includes ClubBook.reading, suggested
  end

  test "suggested scope returns books with suggested status" do
    reading = create(:club_book, status: "reading")
    suggested = create(:club_book, status: "suggested")

    assert_includes ClubBook.suggested, suggested
    assert_not_includes ClubBook.suggested, reading
  end

  test "voting scope returns books with voting status" do
    voting = create(:club_book, status: "voting")
    suggested = create(:club_book, status: "suggested")

    assert_includes ClubBook.voting, voting
    assert_not_includes ClubBook.voting, suggested
  end

  test "completed scope returns books with completed status" do
    completed = create(:club_book, status: "completed")
    reading = create(:club_book, status: "reading")

    assert_includes ClubBook.completed, completed
    assert_not_includes ClubBook.completed, reading
  end

  test "started_at is set when becoming reading" do
    club_book = create(:club_book, status: "suggested")
    assert_nil club_book.started_at

    club_book.update!(status: "reading")

    assert_not_nil club_book.started_at
  end

  test "completed_at is set when becoming completed" do
    club_book = create(:club_book, status: "reading")
    assert_nil club_book.completed_at

    club_book.update!(status: "completed")

    assert_not_nil club_book.completed_at
  end

  test "belongs to club" do
    club = create(:club)
    club_book = create(:club_book, club: club)

    assert_equal club, club_book.club
  end

  test "belongs to book" do
    book = create(:book)
    club_book = create(:club_book, book: book)

    assert_equal book, club_book.book
  end

  test "belongs to suggested_by user" do
    user = create(:user)
    club_book = create(:club_book, suggested_by: user)

    assert_equal user, club_book.suggested_by
  end
end
