class CreateMessageReplies < ActiveRecord::Migration[8.1]
  def change
    create_table :message_replies do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.datetime :edited_at

      t.timestamps
    end

    add_index :message_replies, [ :message_id, :created_at ]
  end
end
