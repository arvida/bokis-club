class AddLanguageToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :language, :string, default: "sv", null: false
  end
end
