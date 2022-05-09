class MakeSubscriptionPlanPolymorphicForUsageRecordsAndSaasFees < ActiveRecord::Migration[6.1]
  def up
    add_column :subscription_plans, :type, :string
    add_column :subscription_plans, :free_trial_ends_at, :datetime
    add_column :subscription_plans, :package_type, :string
  end
end
