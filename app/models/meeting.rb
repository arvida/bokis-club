class Meeting < ApplicationRecord
  LOCATION_TYPES = %w[physical video tbd].freeze

  belongs_to :club
  belongs_to :club_book, optional: true
  has_many :rsvps, dependent: :destroy

  validates :title, presence: true
  validates :scheduled_at, presence: true
  validates :location_type, inclusion: { in: LOCATION_TYPES }
  validate :ends_at_must_be_after_scheduled_at

  scope :active, -> { where(deleted_at: nil) }
  scope :upcoming, -> { active.where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :past, -> { active.where("scheduled_at <= ?", Time.current).order(scheduled_at: :desc) }

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

  private

  def ends_at_must_be_after_scheduled_at
    return if ends_at.blank? || scheduled_at.blank?
    return if ends_at > scheduled_at

    errors.add(:ends_at, "måste vara efter starttid")
  end
end
