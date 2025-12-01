class User < ApplicationRecord
  ALLOWED_AVATAR_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_AVATAR_SIZE = 5.megabytes

  has_one_attached :avatar
  has_many :memberships, -> { active }
  has_many :clubs, through: :memberships
  passwordless_with :email

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 100 }
  validates :locale, inclusion: { in: %w[sv en] }
  validate :acceptable_avatar, if: -> { avatar.attached? }

  before_validation :normalize_email

  def initials
    return "" if name.blank?
    name.split.map { |part| part.first.upcase }.take(2).join
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def acceptable_avatar
    unless avatar.blob.content_type.in?(ALLOWED_AVATAR_TYPES)
      errors.add(:avatar, :invalid_content_type)
    end

    if avatar.blob.byte_size > MAX_AVATAR_SIZE
      errors.add(:avatar, :file_too_large)
    end
  end
end
