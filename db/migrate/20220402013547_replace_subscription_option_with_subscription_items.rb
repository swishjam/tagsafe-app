class ReplaceSubscriptionOptionWithSubscriptionItems < ActiveRecord::Migration[6.1]
  def up
    create_table :subscription_prices do |t|
      t.string :uid, index: true
      t.string :type
      t.string :name
      t.string :slug, index: true
      t.string :stripe_price_id
      t.float :price_in_cents
    end

    create_table :subscription_plan_subscription_prices do |t|
      t.string :uid, index: true
      t.references :subscription_plan, index: { name: :subscription_plan_subscription_prices_on_spl }
      t.references :subscription_price, index: { name: :subscription_plan_subscription_prices_on_spr }
      t.string :stripe_subscription_item_id
    end

    remove_column :subscription_plans, :stripe_flat_fee_subscription_item_id
    remove_column :subscription_plans, :stripe_performance_audit_subscription_item_id
    remove_column :subscription_plans, :stripe_tag_check_subscription_item_id
    remove_column :subscription_plans, :stripe_functional_test_subscription_item_id
    remove_column :subscription_plans, :subscription_option_id

    add_column :domains, :stripe_payment_method_id, :string
  end

  def down
    drop_table :subscription_prices
    drop_table :subscription_plan_subscription_prices
  end
end
