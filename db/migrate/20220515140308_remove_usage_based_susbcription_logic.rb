class RemoveUsageBasedSusbcriptionLogic < ActiveRecord::Migration[6.1]
  def up
    drop_table :subscription_price_options
    drop_table :subscription_prices
    
    remove_column :subscription_plans, :type
    remove_column :domains, :current_saas_subscription_plan_id
    remove_column :domains, :current_usage_based_subscription_plan_id
    
    add_reference :domains, :current_subscription_plan
    add_column :subscription_plans, :billing_interval, :string
    add_column :subscription_plans, :amount, :float
  end
end
