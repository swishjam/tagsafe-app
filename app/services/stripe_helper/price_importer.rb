module StripeHelper
  class PriceImporter
    def import_price_from_stripe(stripe_price_id:, subscription_price_option_klass:, subscription_price_option_name:, package_type: 'custom')
      subscription_price_option_klass.create!(
        name: name,
        stripe_price_id: stripe_price_id,
        subscription_package_type: package_type,
        billing_interval: Stripe::Price.retrieve(stripe_price_id).recurring.interval
      )
    end
  end
end