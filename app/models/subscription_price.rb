class SubscriptionPrice < ApplicationRecord
  belongs_to :subscription_price_option
  belongs_to :subscription_plan

  validates_uniqueness_of :subscription_price_option_id, scope: :subscription_plan_id

  def self.for(subscription_price_option_klass)
    joins(:subscription_price_option).find_by(subscription_price_option: { type: subscription_price_option_klass.to_s })
  end
end