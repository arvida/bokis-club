class User < ApplicationRecord
  has_one_attached :avatar
  passwordless_with :email

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: 100 }
  validates :locale, inclusion: { in: %w[sv en] }

  def initials
    name.split.map { |part| part.first.upcase }.take(2).join
  end
end
