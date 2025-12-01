class AddInviteTrackingToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :invite_expires_at, :datetime
    add_column :clubs, :invite_used_at, :datetime
  end
end
