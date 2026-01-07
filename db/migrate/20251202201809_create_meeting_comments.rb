class CreateMeetingComments < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_comments do |t|
      t.references :meeting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :meeting_comments, [ :meeting_id, :created_at ]
  end
end
