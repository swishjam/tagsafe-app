class AddCurrentFlagToSubscriptionPlan < ActiveRecord::Migration[6.1]
  def up
    add_column :subscription_plans, :current, :boolean
  end
end
