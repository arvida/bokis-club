class CreateBookDiscussionQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :book_discussion_questions do |t|
      t.references :book, null: false, foreign_key: true
      t.string :language, null: false, default: "sv"
      t.text :text, null: false
      t.string :source, null: false

      t.timestamps
    end

    add_index :book_discussion_questions, [ :book_id, :language ]
  end
end
