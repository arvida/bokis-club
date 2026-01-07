require "test_helper"

class DiscussionGuideTest < ActiveSupport::TestCase
  test "valid with meeting" do
    guide = build(:discussion_guide)
    assert guide.valid?
  end

  test "meeting is required" do
    guide = build(:discussion_guide, meeting: nil)
    assert_not guide.valid?
  end

  test "items defaults to empty array" do
    guide = create(:discussion_guide, items: nil)
    assert_equal [], guide.items
  end

  test "add_item creates item with uuid and user_added source" do
    guide = create(:discussion_guide)
    item = guide.add_item("Ny fråga")

    assert_equal "Ny fråga", item["text"]
    assert_equal false, item["checked"]
    assert_equal "user_added", item["source"]
    assert item["id"].present?
    assert_equal 1, guide.reload.items.size
  end

  test "add_item can have custom source" do
    guide = create(:discussion_guide)
    item = guide.add_item("AI fråga", source: "ai_generated")

    assert_equal "ai_generated", item["source"]
  end

  test "remove_item deletes item by id" do
    guide = create(:discussion_guide, :with_items)
    item_id = guide.items.first["id"]

    guide.remove_item(item_id)

    assert_nil guide.reload.find_item(item_id)
    assert_equal 2, guide.items.size
  end

  test "check_item marks item as checked" do
    guide = create(:discussion_guide, :with_items)
    item_id = guide.items.first["id"]

    guide.check_item(item_id)

    assert guide.reload.find_item(item_id)["checked"]
  end

  test "uncheck_item marks item as unchecked" do
    guide = create(:discussion_guide, :with_items)
    item_id = guide.items.first["id"]
    guide.check_item(item_id)

    guide.uncheck_item(item_id)

    assert_not guide.reload.find_item(item_id)["checked"]
  end

  test "toggle_item toggles checked state" do
    guide = create(:discussion_guide, :with_items)
    item_id = guide.items.first["id"]

    assert guide.toggle_item(item_id)
    assert guide.reload.find_item(item_id)["checked"]

    assert guide.toggle_item(item_id)
    assert_not guide.reload.find_item(item_id)["checked"]
  end

  test "toggle_item returns false for non-existent item" do
    guide = create(:discussion_guide)
    assert_not guide.toggle_item("non-existent-id")
  end

  test "find_item returns item by id" do
    guide = create(:discussion_guide, :with_items)
    item_id = guide.items.first["id"]

    found = guide.find_item(item_id)

    assert_equal item_id, found["id"]
  end

  test "find_item returns nil for non-existent id" do
    guide = create(:discussion_guide)
    assert_nil guide.find_item("non-existent")
  end

  test "checked_count returns number of checked items" do
    guide = create(:discussion_guide, :with_items)
    guide.check_item(guide.items.first["id"])
    guide.check_item(guide.items.second["id"])

    assert_equal 2, guide.checked_count
  end

  test "total_count returns number of items" do
    guide = create(:discussion_guide, :with_items)
    assert_equal 3, guide.total_count
  end
end
