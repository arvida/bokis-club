class AddHostToMeetings < ActiveRecord::Migration[8.1]
  def change
    add_reference :meetings, :host, null: true, foreign_key: { to_table: :users }
  end
end
