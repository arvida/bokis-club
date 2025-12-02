class AddTimezoneToClubsAndUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :timezone, :string, default: "Europe/Stockholm"
    add_column :users, :timezone, :string
  end
end
