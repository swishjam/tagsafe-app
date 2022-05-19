module SubscriptionMaintainer
  class Enroller
    attr_accessor :domain

    def initialize(domain, subscription_package:, billing_interval:, amount_in_cents: nil, free_trial_days: 0)
      @domain = domain
      @subscription_package = subscription_package
      @billing_interval = billing_interval
      @free_trial_days = free_trial_days
      @amount_in_cents = amount_in_cents || SubscriptionPlan.price_for(package: subscription_package, billing_interval: billing_interval)
    end

    def enroll!
      create_stripe_subscription!
      create_subscription_plan!
      SubscriptionFeaturesConfiguration.create_or_update_for_domain_by_subscription_package(@subscription_package, @domain)
      FeaturePriceInCredits.create_or_update_for_domain_by_subscription_package(@subscription_package, @domain)
      CreditWallet.for_domain(@domain, create_if_nil: false)&.disable!
      @subscription_plan
    end

    private

    def create_stripe_subscription!
      @stripe_subscription ||= Stripe::Subscription.create(
        customer: @domain.stripe_customer_id,
        trial_period_days: @free_trial_days,
        billing_cycle_anchor: billing_cycle_anchor_date,
        items: [{
          price_data: {
            product: ENV['STRIPE_SUSBCRIPTION_PRODUCT_ID'] || 'prod_LhFczbs5dNe3yo',
            currency: 'usd',
            unit_amount: @amount_in_cents,
            recurring: { interval: @billing_interval.to_s }
          }
        }],
        metadata: { 
          package: @subscription_package, 
          tagsafe_customer_uid: @domain.uid, 
          tagsafe_domain_url: @domain.url,
          env: Rails.env
        }
      )
    end
    alias stripe_subscription create_stripe_subscription!

    def create_subscription_plan!
      @subscription_plan ||= domain.subscription_plans.create!(
        domain: @domain,
        stripe_subscription_id: stripe_subscription.id,
        status: stripe_subscription.status,
        amount: @amount_in_cents,
        billing_interval: @billing_interval,
        package_type: @subscription_package,
        free_trial_ends_at: stripe_subscription.trial_end ? Time.at(stripe_subscription.trial_end).to_datetime : nil
      )
      domain.update!(current_subscription_plan: @subscription_plan)
    end

    def billing_cycle_anchor_date
      next_month = Time.current.next_month.beginning_of_month
      days_until_next_month = (next_month - Time.current) / 1.day
      (@free_trial_days > days_until_next_month ? next_month.next_month : next_month).to_i
    end
  end
end