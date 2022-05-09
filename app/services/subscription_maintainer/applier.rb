module SubscriptionMaintainer
  class Applier
    attr_accessor :domain

    def initialize(domain)
      @domain = domain
    end

    def cancel_current_subscription!
      UsageRecordUpdater.new(domain, usage_records_start_date: DateTime.now.beginning_of_day, usage_records_end_date: DateTime.now.end_of_day).send_usage_records_to_stripe
      saas_stripe_subscription = Stripe::Subscription.delete(domain.current_saas_subscription_plan.stripe_subscription_id, invoice_now: true)
      domain.current_saas_subscription_plan.update!(status: saas_stripe_subscription.status)

      usage_based_stripe_subscription = Stripe::Subscription.delete(domain.current_usage_based_subscription_plan.stripe_subscription_id, invoice_now: true)
      domain.current_usage_based_subscription_plan.update!(status: usage_based_stripe_subscription.status)
    end

    def apply_subscription_package_to_domain(subscription_package:, billing_interval:, free_trial_days: 0)
      create_saas_subscription(subscription_package: subscription_package, billing_interval: billing_interval, free_trial_days: free_trial_days)
      create_usage_based_subscription(subscription_package: subscription_package, free_trial_days: free_trial_days)      
      SubscriptionFeatureRestriction.create_default_for_subscription_package(subscription_package, domain)
    end

    private

    def create_saas_subscription(subscription_package:, billing_interval:, free_trial_days: 0)
      stripe_subscription = Stripe::Subscription.create(
        customer: domain.stripe_customer_id,
        trial_period_days: free_trial_days,
        items: [{ price: SaasFeeSubscriptionPriceOption.for_subscription_package_and_billing_interval(subscription_package, billing_interval).stripe_price_id }],
        metadata: { 
          package: subscription_package, 
          subscription_type: 'SaaS fees', 
          tagsafe_customer_uid: domain.uid, 
          tagsafe_domain_url: domain.url 
        }
      )
      subscription_plan = create_subscription_plan(stripe_subscription: stripe_subscription, package_type: subscription_package, subscription_plan_klass: SaasSubscriptionPlan)
      domain.update!(current_saas_subscription_plan: subscription_plan)
    end

    def create_usage_based_subscription(subscription_package:, free_trial_days: 0)
      stripe_subscription = Stripe::Subscription.create(
        customer: domain.stripe_customer_id,
        trial_period_days: free_trial_days,
        items: [
          { price: PerAutomatedPerformanceAuditSubscriptionPriceOption.for_subscription_package_and_billing_interval(subscription_package, 'month').stripe_price_id },
          { price: PerAutomatedTestRunSubscriptionPriceOption.for_subscription_package_and_billing_interval(subscription_package, 'month').stripe_price_id },
          { price: PerReleaseCheckSubscriptionPriceOption.for_subscription_package_and_billing_interval(subscription_package, 'month').stripe_price_id },
          { price: PerUptimeCheckSubscriptionPriceOption.for_subscription_package_and_billing_interval(subscription_package, 'month').stripe_price_id },
        ],
        metadata: { 
          package: subscription_package, 
          subscription_type: 'Usage-based fees', 
          tagsafe_customer_uid: domain.uid, 
          tagsafe_domain_url: domain.url 
        }
      )
      subscription_plan = create_subscription_plan(stripe_subscription: stripe_subscription, package_type: subscription_package, subscription_plan_klass: UsageBasedSubscriptionPlan)
      domain.update!(current_usage_based_subscription_plan: subscription_plan)
    end

    def create_subscription_plan(stripe_subscription:, package_type:, subscription_plan_klass:)
      subscription_prices_attributes = stripe_subscription.items.data.map do |stripe_subscription_item|
        {
          stripe_subscription_item_id: stripe_subscription_item.id,
          subscription_price_option: SubscriptionPriceOption.find_by!(stripe_price_id: stripe_subscription_item.price.id)
        }
      end
      subscription_plan_klass.create!(
        domain: domain,
        stripe_subscription_id: stripe_subscription.id,
        status: stripe_subscription.status,
        package_type: package_type,
        free_trial_ends_at: stripe_subscription.trial_end ? Time.at(stripe_subscription.trial_end).to_datetime : nil,
        subscription_prices_attributes: subscription_prices_attributes
      )
    end
  end
end