class ChangeClubBookUniquenessToPartialIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :club_books, [ :club_id, :book_id ], unique: true
    add_index :club_books, [ :club_id, :book_id ],
              unique: true,
              where: "deleted_at IS NULL",
              name: "index_club_books_on_club_id_and_book_id_active"
  end
end
