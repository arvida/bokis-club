class AddStateToMeetings < ActiveRecord::Migration[8.1]
  def change
    add_column :meetings, :state, :string, default: "scheduled", null: false
    add_column :meetings, :started_at, :datetime
    add_column :meetings, :ended_at, :datetime
    add_column :meetings, :regenerate_count, :integer, default: 0, null: false
    add_index :meetings, :state
  end
end
