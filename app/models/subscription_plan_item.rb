class SubscriptionPlanItem < ApplicationRecord
  belongs_to :subscription_price
  belongs_to :subscription_plan

  validates_uniqueness_of :subscription_price_id, scope: :subscription_plan_id
end