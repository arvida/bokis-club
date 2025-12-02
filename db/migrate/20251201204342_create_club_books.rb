class CreateClubBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :club_books do |t|
      t.references :club, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.references :suggested_by, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "suggested"
      t.text :notes
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :club_books, [ :club_id, :book_id ], unique: true
    add_index :club_books, :status
    add_index :club_books, :deleted_at
  end
end
