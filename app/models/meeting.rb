class Meeting < ApplicationRecord
  LOCATION_TYPES = %w[physical video tbd].freeze
  STATES = %w[scheduled live ended].freeze

  # Virtual attribute for questions provided during creation
  attr_accessor :initial_questions

  belongs_to :club
  belongs_to :club_book, optional: true
  belongs_to :host, class_name: "User", optional: true
  has_many :rsvps, dependent: :destroy
  has_many :comments, class_name: "MeetingComment", dependent: :destroy
  has_one :discussion_guide, dependent: :destroy

  after_create :setup_discussion_guide

  validates :title, presence: true
  validates :scheduled_at, presence: true
  validates :location_type, inclusion: { in: LOCATION_TYPES }
  validates :state, inclusion: { in: STATES }
  validate :ends_at_must_be_after_scheduled_at

  scope :active, -> { where(deleted_at: nil) }
  scope :upcoming, -> { active.where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :past, -> { active.where("scheduled_at <= ?", Time.current).order(scheduled_at: :desc) }
  scope :live, -> { active.where(state: "live") }
  scope :ended, -> { active.where(state: "ended") }

  # State predicates
  def scheduled?
    state == "scheduled"
  end

  def live?
    state == "live"
  end

  def ended?
    state == "ended"
  end

  # State transitions
  def start!
    return false if live?

    update!(state: "live", started_at: started_at || Time.current)
  end

  def end!
    return false unless live?

    update!(state: "ended", ended_at: Time.current)
  end

  def resume!
    return false unless ended?

    update!(state: "live", ended_at: nil)
  end

  # Regeneration tracking
  def can_regenerate?
    regenerate_count < 3
  end

  def increment_regenerate!
    increment!(:regenerate_count)
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def duration
    return nil unless ends_at.present?

    ((ends_at - scheduled_at) / 60).to_i
  end

  def maps_url
    return nil unless location_type == "physical"
    return nil if location.blank?

    "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(location)}"
  end

  def rsvps_by_response
    @rsvps_by_response ||= rsvps.includes(:user).group_by(&:response)
  end

  def attendees
    (rsvps_by_response["yes"] || []).map(&:user)
  end

  def maybe_attendees
    (rsvps_by_response["maybe"] || []).map(&:user)
  end

  def declined
    (rsvps_by_response["no"] || []).map(&:user)
  end

  def rsvp_for(user)
    rsvps.find_by(user: user)
  end

  def attendee_count
    rsvps.where(response: "yes").count
  end

  def maybe_count
    rsvps.where(response: "maybe").count
  end

  def checked_in_attendees
    rsvps.where(response: "yes").where.not(checked_in_at: nil).includes(:user).map(&:user)
  end

  def checked_in_count
    rsvps.where(response: "yes").where.not(checked_in_at: nil).count
  end

  def can_manage?(user)
    return false unless user

    host == user || club.admin?(user)
  end

  private

  def setup_discussion_guide
    guide = create_discussion_guide!

    # Use provided questions if any
    provided_questions = Array(initial_questions).reject(&:blank?)
    if provided_questions.any?
      provided_questions.each do |text|
        guide.add_item(text, source: "user_added")
      end
      return
    end

    # Otherwise, generate questions if we have a book
    return unless club_book&.book

    generator = DiscussionQuestionGenerator.new
    questions = generator.generate_for_book(club_book.book, language: club.language, count: 2)

    questions.first(2).each do |question|
      guide.add_item(question.text, source: question.source)
    end
  end

  def ends_at_must_be_after_scheduled_at
    return if ends_at.blank? || scheduled_at.blank?
    return if ends_at > scheduled_at

    errors.add(:ends_at, "måste vara efter starttid")
  end
end
