class AddPeopleCountToHelpRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :help_requests, :people_count, :integer
  end
end
