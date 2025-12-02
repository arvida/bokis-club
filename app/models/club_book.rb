class ClubBook < ApplicationRecord
  STATUSES = %w[suggested voting next reading completed].freeze

  belongs_to :club
  belongs_to :book
  belongs_to :suggested_by, class_name: "User", optional: true
  has_many :votes, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :club_id, uniqueness: { scope: :book_id, conditions: -> { where(deleted_at: nil) } }
  validate :only_one_next_per_club, if: -> { status == "next" }

  before_save :set_started_at, if: -> { status_changed? && status == "reading" }
  before_save :set_completed_at, if: -> { status_changed? && status == "completed" }

  scope :active, -> { where(deleted_at: nil) }
  scope :suggested, -> { where(status: "suggested") }
  scope :voting, -> { where(status: "voting") }
  scope :next_up, -> { where(status: "next") }
  scope :reading, -> { where(status: "reading") }
  scope :completed, -> { where(status: "completed") }

  def soft_deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def vote_count
    votes.size
  end

  private

  def only_one_next_per_club
    existing = club.club_books.active.next_up.where.not(id: id).exists?
    errors.add(:status, :only_one_next) if existing
  end

  def set_started_at
    self.started_at ||= Time.current
  end

  def set_completed_at
    self.completed_at ||= Time.current
  end
end
