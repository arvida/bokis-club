class AddClubIdStatusIndexToClubBooks < ActiveRecord::Migration[8.1]
  def change
    add_index :club_books, [ :club_id, :status ]
  end
end
