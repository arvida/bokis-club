class CreateClubs < ActiveRecord::Migration[8.1]
  def change
    create_table :clubs do |t|
      t.string :name, null: false
      t.text :description
      t.string :privacy, default: "closed", null: false
      t.string :invite_code, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :clubs, :invite_code, unique: true
    add_index :clubs, :deleted_at
  end
end
