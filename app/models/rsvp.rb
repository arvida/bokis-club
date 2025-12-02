class Rsvp < ApplicationRecord
  RESPONSES = %w[yes maybe no].freeze

  belongs_to :meeting
  belongs_to :user

  validates :response, presence: true, inclusion: { in: RESPONSES }
  validate :one_per_user_per_meeting
  validate :user_must_be_club_member

  private

  def one_per_user_per_meeting
    return if meeting.blank? || user.blank?

    existing = Rsvp.where(meeting: meeting, user: user)
    existing = existing.where.not(id: id) if persisted?
    return unless existing.exists?

    errors.add(:user_id, "har redan svarat på denna träff")
  end

  def user_must_be_club_member
    return if meeting.blank? || user.blank?
    return if meeting.club.member?(user)

    errors.add(:user, "måste vara medlem i klubben")
  end
end
