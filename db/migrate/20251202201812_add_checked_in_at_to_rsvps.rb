class AddCheckedInAtToRsvps < ActiveRecord::Migration[8.1]
  def change
    add_column :rsvps, :checked_in_at, :datetime
  end
end
