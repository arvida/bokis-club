class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :google_books_id
      t.string :title, null: false
      t.string :authors, array: true, default: []
      t.text :description
      t.integer :page_count
      t.string :cover_url
      t.string :isbn
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :books, :google_books_id, unique: true, where: "google_books_id IS NOT NULL"
    add_index :books, :deleted_at
  end
end
