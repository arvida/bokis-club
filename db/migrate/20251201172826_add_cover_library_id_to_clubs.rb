class AddCoverLibraryIdToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :cover_library_id, :string
  end
end
