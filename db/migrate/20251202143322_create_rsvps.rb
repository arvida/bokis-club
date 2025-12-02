class CreateRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :rsvps do |t|
      t.references :meeting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :response, null: false
      t.timestamps
    end

    add_index :rsvps, [ :meeting_id, :user_id ], unique: true
  end
end
