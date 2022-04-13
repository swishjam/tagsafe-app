class SubscriptionBilling < ApplicationRecord
  belongs_to :domain
  belongs_to :subscription_plan
end