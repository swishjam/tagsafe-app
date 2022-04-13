class CreateSubscriptionPlans < ActiveRecord::Migration[6.1]
  def up
    create_table :subscription_plans do |t|
      t.string :uid, index: true
      t.references :domain
      t.references :subscription_option
      t.string :stripe_subscription_id
      t.string :status
      t.string :stripe_flat_fee_subscription_item_id
      t.string :stripe_performance_audit_subscription_item_id
      t.string :stripe_tag_check_subscription_item_id
      t.string :stripe_functional_test_subscription_item_id
      t.timestamps
    end
    remove_column :domains, :stripe_subscription_id
    remove_column :domains, :subscription_option_id

    add_column :subscription_categories, :stripe_functional_test_monthly_price_id, :string
    add_column :subscription_categories, :stripe_functional_test_annual_price_id, :string
    
    rename_column :subscription_categories, :stripe_audit_monthly_price_id, :stripe_performance_audit_monthly_price_id
    rename_column :subscription_categories, :stripe_audit_annual_price_id, :stripe_performance_audit_annual_price_id

    remove_column :subscription_categories, :stripe_performance_audit_annual_price_id
    remove_column :subscription_categories, :stripe_functional_test_annual_price_id
    remove_column :subscription_categories, :stripe_tag_check_annual_price_id

    rename_table :subscription_categories, :subscription_options
  end

  def down
  end
end
