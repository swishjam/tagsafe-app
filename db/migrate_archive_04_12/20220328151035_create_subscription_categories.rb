class CreateSubscriptionCategories < ActiveRecord::Migration[6.1]
  def up
    create_table :subscription_categories do |t|
      t.string :uid, index: true
      t.string :name
      t.string :slug, index: true
      t.string :stripe_flat_fee_monthly_price_id
      t.string :stripe_flat_fee_annual_price_id
      t.string :stripe_tag_check_monthly_price_id
      t.string :stripe_tag_check_annual_price_id
      t.string :stripe_audit_monthly_price_id
      t.string :stripe_audit_annual_price_id
      t.timestamps
    end

    add_reference :domains, :subscription_option
  end

  def down
  end
end
