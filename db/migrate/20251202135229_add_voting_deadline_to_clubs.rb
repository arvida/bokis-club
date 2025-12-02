class AddVotingDeadlineToClubs < ActiveRecord::Migration[8.1]
  def change
    add_column :clubs, :voting_deadline, :datetime
  end
end
