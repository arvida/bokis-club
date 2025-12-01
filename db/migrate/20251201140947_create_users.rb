class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :locale, default: "sv"

      t.timestamps
    end

    add_index :users, "lower(email)", unique: true, name: "index_users_on_lowercase_email"
  end
end
