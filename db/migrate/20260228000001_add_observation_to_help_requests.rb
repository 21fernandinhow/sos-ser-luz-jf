class AddObservationToHelpRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :help_requests, :observation, :text
  end
end
