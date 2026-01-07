class CreateDiscussionGuides < ActiveRecord::Migration[8.1]
  def change
    create_table :discussion_guides do |t|
      t.references :meeting, null: false, foreign_key: true
      t.jsonb :items, default: []

      t.timestamps
    end
  end
end
