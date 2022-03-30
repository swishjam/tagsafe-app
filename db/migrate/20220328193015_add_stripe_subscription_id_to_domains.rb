class AddStripeSubscriptionIdToDomains < ActiveRecord::Migration[6.1]
  def up
    add_column :domains, :stripe_subscription_id, :string
  end
end
