class ChangeSubscriptionPlanSubscriptionPriceTableName < ActiveRecord::Migration[6.1]
  def up
    rename_table :subscription_plan_subscription_prices, :subscription_plan_items

    create_table :subscription_billings do |t|
      t.string :uid, index: true
      t.references :subscription_plan
      t.references :domain
      t.float :billed_amount_in_cents
      t.datetime :bill_start_datetime
      t.datetime :bill_end_datetime
    end
  end

  def down
  end
end
