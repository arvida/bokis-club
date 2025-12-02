require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "valid book with all required attributes" do
    book = build(:book)
    assert book.valid?
  end

  test "title is required" do
    book = build(:book, title: nil)
    assert_not book.valid?
    assert_includes book.errors[:title], "måste anges"
  end

  test "title must not exceed 500 characters" do
    book = build(:book, title: "A" * 501)
    assert_not book.valid?
    assert_includes book.errors[:title], "är för lång (max 500 tecken)"
  end

  test "google_books_id is optional" do
    book = build(:book, google_books_id: nil)
    assert book.valid?
  end

  test "google_books_id must be unique when present" do
    create(:book, google_books_id: "abc123")
    duplicate = build(:book, google_books_id: "abc123")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:google_books_id], "används redan"
  end

  test "google_books_id uniqueness allows multiple nil values" do
    create(:book, google_books_id: nil)
    another = build(:book, google_books_id: nil)
    assert another.valid?
  end

  test "authors defaults to empty array" do
    book = Book.new(title: "Test Book")
    assert_equal [], book.authors
  end

  test "authors can be set as array" do
    book = build(:book, authors: [ "Anna Svensson", "Erik Johansson" ])
    assert_equal [ "Anna Svensson", "Erik Johansson" ], book.authors
  end

  test "description is optional" do
    book = build(:book, description: nil)
    assert book.valid?
  end

  test "page_count is optional" do
    book = build(:book, page_count: nil)
    assert book.valid?
  end

  test "page_count must be positive when present" do
    book = build(:book, page_count: 0)
    assert_not book.valid?
    assert_includes book.errors[:page_count], "måste vara större än 0"
  end

  test "cover_url is optional" do
    book = build(:book, cover_url: nil)
    assert book.valid?
  end

  test "isbn is optional" do
    book = build(:book, isbn: nil)
    assert book.valid?
  end

  test "deleted_at defaults to nil" do
    book = create(:book)
    assert_nil book.deleted_at
  end

  test "soft_deleted? returns false when deleted_at is nil" do
    book = build(:book, deleted_at: nil)
    assert_not book.soft_deleted?
  end

  test "soft_deleted? returns true when deleted_at is present" do
    book = build(:book, deleted_at: Time.current)
    assert book.soft_deleted?
  end

  test "soft_delete! sets deleted_at" do
    book = create(:book)
    assert_nil book.deleted_at

    book.soft_delete!

    assert_not_nil book.deleted_at
    assert book.soft_deleted?
  end

  test "active scope excludes soft deleted books" do
    active_book = create(:book)
    deleted_book = create(:book)
    deleted_book.soft_delete!

    assert_includes Book.active, active_book
    assert_not_includes Book.active, deleted_book
  end

  test "manual_entry? returns true when google_books_id is nil" do
    book = build(:book, google_books_id: nil)
    assert book.manual_entry?
  end

  test "manual_entry? returns false when google_books_id is present" do
    book = build(:book, google_books_id: "abc123")
    assert_not book.manual_entry?
  end

  test "author_names returns comma-separated string" do
    book = build(:book, authors: [ "Anna Svensson", "Erik Johansson" ])
    assert_equal "Anna Svensson, Erik Johansson", book.author_names
  end

  test "author_names returns empty string for no authors" do
    book = build(:book, authors: [])
    assert_equal "", book.author_names
  end

  test "cover_placeholder_color returns vermillion or sage based on id" do
    book1 = create(:book)
    book2 = create(:book)

    colors = [ book1.cover_placeholder_color, book2.cover_placeholder_color ]
    assert colors.all? { |c| %w[vermillion sage].include?(c) }
  end

  test "cover_placeholder_color is deterministic for same book" do
    book = create(:book)
    assert_equal book.cover_placeholder_color, book.cover_placeholder_color
  end

  test "cover_url_at_size returns nil when cover_url is blank" do
    book = build(:book, cover_url: nil)
    assert_nil book.cover_url_at_size(:large)
  end

  test "cover_url_at_size changes zoom parameter for different sizes" do
    book = build(:book, cover_url: "https://books.google.com/content?id=abc&zoom=1")

    assert_equal "https://books.google.com/content?id=abc&zoom=1", book.cover_url_at_size(:small)
    assert_equal "https://books.google.com/content?id=abc&zoom=2", book.cover_url_at_size(:medium)
    assert_equal "https://books.google.com/content?id=abc&zoom=3", book.cover_url_at_size(:large)
    assert_equal "https://books.google.com/content?id=abc&zoom=4", book.cover_url_at_size(:extra_large)
  end

  test "cover_url_at_size returns original url if no zoom parameter" do
    book = build(:book, cover_url: "https://example.com/cover.jpg")
    assert_equal "https://example.com/cover.jpg", book.cover_url_at_size(:large)
  end

  test "cover_url_at_size defaults to medium" do
    book = build(:book, cover_url: "https://books.google.com/content?id=abc&zoom=1")
    assert_equal "https://books.google.com/content?id=abc&zoom=2", book.cover_url_at_size
  end
end
