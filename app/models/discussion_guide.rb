class DiscussionGuide < ApplicationRecord
  belongs_to :meeting

  # Items structure: [{id: uuid, text: "...", checked: false, source: "ai_generated"}]

  after_update_commit :broadcast_guide_update

  private

  def broadcast_guide_update
    broadcast_replace_to meeting,
      target: "discussion-guide",
      partial: "meetings/discussion_guide_section",
      locals: { meeting: meeting, club: meeting.club }
  end

  public

  def items
    super || []
  end

  def check_item(item_id)
    updated = items.map { |i| i["id"] == item_id ? i.merge("checked" => true) : i }
    update!(items: updated)
  end

  def uncheck_item(item_id)
    updated = items.map { |i| i["id"] == item_id ? i.merge("checked" => false) : i }
    update!(items: updated)
  end

  def toggle_item(item_id)
    item = find_item(item_id)
    return false unless item

    if item["checked"]
      uncheck_item(item_id)
    else
      check_item(item_id)
    end
    true
  end

  def add_item(text, source: "user_added")
    new_item = {
      "id" => SecureRandom.uuid,
      "text" => text,
      "checked" => false,
      "source" => source
    }
    update!(items: items + [ new_item ])
    new_item
  end

  def remove_item(item_id)
    update!(items: items.reject { |i| i["id"] == item_id })
  end

  def find_item(item_id)
    items.find { |i| i["id"] == item_id }
  end

  def checked_count
    items.count { |i| i["checked"] }
  end

  def total_count
    items.size
  end
end
