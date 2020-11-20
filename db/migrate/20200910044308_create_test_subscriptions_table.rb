class CreateTestSubscriptionsTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :domains_tests
    create_table :test_subscriptions do |t|
      t.references :domain
      t.references :test
      t.references :script
    end
  end
end
