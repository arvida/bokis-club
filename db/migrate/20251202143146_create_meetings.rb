class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.references :club, null: false, foreign_key: true
      t.references :club_book, foreign_key: true
      t.string :title, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :ends_at
      t.string :location_type, default: "tbd"
      t.text :location
      t.text :notes
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :meetings, [ :club_id, :scheduled_at ]
    add_index :meetings, :deleted_at
  end
end
