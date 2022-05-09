class RenameSubscriptionTables < ActiveRecord::Migration[6.1]
  def up
    rename_table :subscription_prices, :subscription_price_options
    rename_table :subscription_plan_items, :subscription_prices

    remove_column :subscription_prices, :subscription_price_id
    add_reference :subscription_prices, :subscription_price_option

    rename_table :subscription_billings, :subscription_usage_record_updates
    
    add_column :subscription_price_options, :subscription_package_type, :string
    add_column :subscription_price_options, :billing_interval, :string
  end
end
