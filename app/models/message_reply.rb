class MessageReply < ApplicationRecord
  include ActionView::RecordIdentifier

  EDIT_WINDOW = 15.minutes

  belongs_to :message
  belongs_to :user

  validates :content, presence: true, length: { maximum: 1000 }

  after_create_commit -> { broadcast_append_to message, target: dom_id(message, :replies) }
  after_update_commit -> { broadcast_replace_to message }
  after_destroy_commit -> { broadcast_remove_to message }

  def club
    message.club
  end

  def editable_by?(user)
    return false if user.nil?

    self.user == user && created_at > EDIT_WINDOW.ago
  end

  def destroyable_by?(user)
    return false if user.nil?

    self.user == user || club.admin?(user)
  end

  def edited?
    edited_at.present?
  end
end
