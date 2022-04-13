class AddStripeCustomerIdToDomains < ActiveRecord::Migration[6.1]
  def up
    add_column :domains, :stripe_customer_id, :string
  end

  def down
    remove_column :domains, :stripe_customer_id
  end
end
