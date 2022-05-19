module SubscriptionMaintainer
  class Remover
    attr_accessor :domain

    def initialize(domain)
      @domain = domain
    end

    def cancel_current_subscription!
      stripe_subscription = Stripe::Subscription.delete(domain.current_subscription_plan.stripe_subscription_id, invoice_now: true)
      CreditWallet.for_domain(domain).disable!
      domain.current_subscription_plan.update!(status: stripe_subscription.status)
    end
  end
end