class MoveCurrentSubscriptionPlanColumnsToDomain < ActiveRecord::Migration[6.1]
  def up
    add_reference :domains, :current_saas_subscription_plan
    add_reference :domains, :current_usage_based_subscription_plan

    remove_column :subscription_plans, :current
  end
end
