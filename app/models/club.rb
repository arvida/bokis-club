class Club < ApplicationRecord
  COVER_IMAGES = [
    { id: "library-1", name: "Klassiskt bibliotek", path: "covers/library-1.jpg" },
    { id: "library-2", name: "Modernt bibliotek", path: "covers/library-2.jpg" },
    { id: "bookshelf-1", name: "Bokhylla", path: "covers/bookshelf-1.jpg" },
    { id: "bookshelf-2", name: "Färgglad bokhylla", path: "covers/bookshelf-2.jpg" },
    { id: "nook-1", name: "Läshörna", path: "covers/nook-1.jpg" },
    { id: "nook-2", name: "Mysig läsplats", path: "covers/nook-2.jpg" },
    { id: "cafe-1", name: "Bokcafé", path: "covers/cafe-1.jpg" },
    { id: "vintage-1", name: "Antikvarisk bokhandel", path: "covers/vintage-1.jpg" }
  ].freeze

  DEFAULT_COVER = "covers/default.jpg"

  has_one_attached :cover_image
  has_many :memberships, -> { active }
  has_many :members, through: :memberships, source: :user
  has_many :club_books, -> { active }
  has_many :books, through: :club_books
  has_many :meetings, -> { active }
  has_many :messages, dependent: :destroy

  LANGUAGES = %w[sv en].freeze

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :privacy, inclusion: { in: %w[open closed] }
  validates :language, inclusion: { in: LANGUAGES }
  validates :invite_code, presence: true, uniqueness: true
  validate :timezone_must_be_valid

  before_validation :generate_invite_code, on: :create

  scope :active, -> { where(deleted_at: nil) }

  def admins
    User.joins(:memberships).where(memberships: { club_id: id, role: "admin", deleted_at: nil })
  end

  def admin?(user)
    memberships.exists?(user: user, role: "admin")
  end

  def member?(user)
    memberships.exists?(user: user)
  end

  def current_book
    club_books.reading.includes(:book).first&.book
  end

  def current_club_book
    club_books.reading.first
  end

  def next_book
    club_books.next_up.includes(:book).first&.book
  end

  def next_club_book
    club_books.next_up.first
  end

  def suggested_books
    club_books.suggested.includes(:book)
  end

  def voting_books
    club_books.voting.includes(:book)
  end

  def voting_deadline_passed?
    voting_deadline.present? && voting_deadline < Time.current
  end

  def clear_voting_deadline!
    update!(voting_deadline: nil)
  end

  def completed_books
    club_books.completed.includes(:book).order(completed_at: :desc)
  end

  def cover_url
    if cover_image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(cover_image, only_path: true)
    elsif cover_library_id.present?
      find_library_cover_path
    else
      DEFAULT_COVER
    end
  end

  def soft_deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def regenerate_invite_code!
    update!(
      invite_code: generate_code,
      invite_expires_at: 14.days.from_now,
      invite_used_at: nil
    )
  end

  def invite_valid?
    return false if invite_used_at.present?
    return false if invite_expires_at.present? && invite_expires_at < Time.current
    true
  end

  def mark_invite_used!
    update!(invite_used_at: Time.current)
  end

  def invite_url
    Rails.application.routes.url_helpers.invite_url(invite_code, host: default_url_host)
  end

  private

  def generate_invite_code
    self.invite_code ||= generate_code
  end

  def generate_code
    loop do
      code = SecureRandom.alphanumeric(8).downcase
      break code unless Club.exists?(invite_code: code)
    end
  end

  def find_library_cover_path
    cover = COVER_IMAGES.find { |img| img[:id] == cover_library_id }
    cover ? cover[:path] : DEFAULT_COVER
  end

  def default_url_host
    Rails.application.config.action_mailer.default_url_options[:host] || "localhost"
  end

  def timezone_must_be_valid
    return if timezone.blank?
    return if ActiveSupport::TimeZone[timezone].present?

    errors.add(:timezone, :invalid)
  end
end
