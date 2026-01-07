class Rsvp < ApplicationRecord
  RESPONSES = %w[yes maybe no].freeze

  belongs_to :meeting
  belongs_to :user

  validates :response, presence: true, inclusion: { in: RESPONSES }
  validate :one_per_user_per_meeting
  validate :user_must_be_club_member

  after_update_commit :broadcast_check_in_change, if: :saved_change_to_checked_in_at?

  scope :checked_in, -> { where.not(checked_in_at: nil) }

  def checked_in?
    checked_in_at.present?
  end

  def check_in!
    return false if checked_in?
    return false unless response == "yes"

    update!(checked_in_at: Time.current)
  end

  def undo_check_in!
    return false unless checked_in?

    update!(checked_in_at: nil)
  end

  private

  def broadcast_check_in_change
    broadcast_replace_to meeting,
      target: "checked-in-count",
      partial: "meetings/checked_in_count",
      locals: { meeting: meeting }

    broadcast_replace_to meeting,
      target: "checked-in-avatars",
      partial: "meetings/checked_in_avatars",
      locals: { meeting: meeting }
  end

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
