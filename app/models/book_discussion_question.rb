class BookDiscussionQuestion < ApplicationRecord
  SOURCES = %w[ai_generated user_added].freeze
  LANGUAGES = %w[sv en].freeze

  belongs_to :book

  validates :text, presence: true
  validates :source, inclusion: { in: SOURCES }
  validates :language, inclusion: { in: LANGUAGES }

  scope :for_language, ->(lang) { where(language: lang) }
  scope :fresh, -> { where("created_at > ?", 6.months.ago) }
  scope :ai_generated, -> { where(source: "ai_generated") }
  scope :user_added, -> { where(source: "user_added") }

  def self.random_sample(count)
    order("RANDOM()").limit(count)
  end
end
