class Book < ApplicationRecord
  validates :title, presence: true, length: { maximum: 500 }
  validates :google_books_id, uniqueness: true, allow_nil: true
  validates :page_count, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(deleted_at: nil) }

  def soft_deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def manual_entry?
    google_books_id.nil?
  end

  def author_names
    authors.join(", ")
  end

  def cover_placeholder_color
    id.to_i.even? ? "vermillion" : "sage"
  end
end
