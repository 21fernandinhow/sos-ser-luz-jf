class CreateHelpRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :help_requests do |t|
      t.string :name, null: false
      t.string :phone
      t.string :address, null: false
      t.string :neighborhood, null: false
      t.text :need, null: false
      t.string :situation_type
      t.boolean :urgent, default: false
      t.string :status, default: "pending"

      t.timestamps
    end
  end
end
