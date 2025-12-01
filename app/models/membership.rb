class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :club

  validates :role, inclusion: { in: %w[admin member] }
  validates :user_id, uniqueness: { scope: :club_id }

  scope :active, -> { where(deleted_at: nil) }
  scope :admins, -> { where(role: "admin") }

  def admin?
    role == "admin"
  end

  def soft_deleted?
    deleted_at.present?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end
end
