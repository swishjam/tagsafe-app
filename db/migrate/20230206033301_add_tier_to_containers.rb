class AddTierToContainers < ActiveRecord::Migration[6.1]
  def change
    add_column :containers, :subscription_tier, :string
  end
end
