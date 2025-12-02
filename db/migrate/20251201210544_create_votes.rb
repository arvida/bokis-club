class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :club_book, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :votes, [ :club_book_id, :user_id ], unique: true
  end
end
