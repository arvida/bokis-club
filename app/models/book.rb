class Book < ApplicationRecord
  has_many :discussion_questions, class_name: "BookDiscussionQuestion", dependent: :destroy

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

  # Returns cover URL at specified size
  # Google Books zoom levels: 1 (small), 2 (medium), 3 (large), 4 (extra large)
  def cover_url_at_size(size = :medium)
    return nil if cover_url.blank?

    zoom = case size
    when :small then 1
    when :medium then 2
    when :large then 3
    when :extra_large then 4
    else 2
    end

    if cover_url.include?("zoom=")
      cover_url.gsub(/zoom=\d/, "zoom=#{zoom}")
    else
      cover_url
    end
  end
end
