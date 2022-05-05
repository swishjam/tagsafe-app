class SaasSubscriptionPlan < SubscriptionPlan
  has_one :current_domain, class_name: Domain.to_s, foreign_key: :current_saas_subscription_plan_id

  def subscription_price
    subscription_prices.for(SaasFeeSubscriptionPriceOption)
  end

  def billing_interval
    subscription_price.subscription_price_option.billing_interval
  end
end