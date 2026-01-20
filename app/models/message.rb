class Message < ApplicationRecord
  EDIT_WINDOW = 15.minutes

  belongs_to :club
  belongs_to :user
  has_many :replies, class_name: "MessageReply", dependent: :destroy

  validates :content, presence: true, length: { maximum: 2000 }

  after_create_commit -> { broadcast_append_to club, target: "messages-list" }
  after_update_commit -> { broadcast_replace_to club }
  after_destroy_commit -> { broadcast_remove_to club }

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
