class MeetingComment < ApplicationRecord
  belongs_to :meeting
  belongs_to :user

  validates :content, presence: true, length: { maximum: 1000 }
  validate :meeting_must_be_live_or_ended

  after_create_commit -> { broadcast_append_to meeting, target: "meeting-comments" }
  after_update_commit -> { broadcast_replace_to meeting }
  after_destroy_commit -> { broadcast_remove_to meeting }

  def editable_by?(user)
    self.user == user
  end

  private

  def meeting_must_be_live_or_ended
    return if meeting.blank?
    return if meeting.live? || meeting.ended?

    errors.add(:meeting, "måste vara live eller avslutad för att lägga till kommentarer")
  end
end
