module SubscriptionMaintainer
  class Updater
    def initialize(domain, subscription_package:, billing_interval:, amount_in_cents: nil)
      @domain = domain
      @subscription_package = subscription_package
      @billing_interval = billing_interval
      @amount_in_cents = amount_in_cents || SubscriptionPlan.price_for(package: subscription_package, billing_interval: billing_interval)
    end

    def update_current_subscription!
      update_stripe_subscription!
      update_subscription_plan!
      SubscriptionFeaturesConfiguration.create_or_update_for_domain_by_subscription_package(@subscription_package, @domain)
      FeaturePriceInCredits.create_or_update_for_domain_by_subscription_package(@subscription_package, @domain)
      existing_credit_wallet = CreditWallet.for_domain(@domain, create_if_nil: false)
      if existing_credit_wallet
        WalletModerator::UpdateCreditsAfterSubscriptionChange.new(existing_credit_wallet).update!
      end
    end

    private

    def update_stripe_subscription!
      @stripe_susbcription ||= begin
        subscription_item_id_to_update = Stripe::Subscription.retrieve(@domain.current_subscription_plan.stripe_subscription_id).items.first.id
        Stripe::Subscription.update(
          @domain.current_subscription_plan.stripe_subscription_id,
          proration_behavior: 'always_invoice',
          items: [{
            id: subscription_item_id_to_update,
            price_data: {
              product: ENV['STRIPE_SUSBCRIPTION_PRODUCT_ID'] || 'prod_LhFczbs5dNe3yo',
              currency: 'usd',
              unit_amount: @amount_in_cents,
              recurring: { interval: @billing_interval.to_s }
            }
          }]
        )
      end
    end
    alias stripe_subscription update_stripe_subscription!

    def update_subscription_plan!
      @domain.current_subscription_plan.update!(
        status: stripe_subscription.status,
        amount: @amount_in_cents,
        billing_interval: @billing_interval,
        package_type: @subscription_package,
        free_trial_ends_at: stripe_subscription.trial_end ? Time.at(stripe_subscription.trial_end).to_datetime : nil
      )
    end
  end
end