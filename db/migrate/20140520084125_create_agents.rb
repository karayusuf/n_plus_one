class CreateAgents < ActiveRecord::Migration
  def change
    create_table :agents do |t|
      t.integer :account_id
      t.string :name

      t.timestamps
    end
  end
end
