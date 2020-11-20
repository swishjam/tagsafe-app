class ChangeTestSubscriptionsToTestSubscribers < ActiveRecord::Migration[5.2]
  def change
    rename_table :test_subscriptions, :test_subscribers
  end
end
