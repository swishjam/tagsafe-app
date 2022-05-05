module Admin
  class SubscriptionPricesController < BaseController
    def index
      @subscription_price_options = SubscriptionPriceOption.all.includes(:subscription_prices).order(:subscription_package_type).page(params[:page] || 1).per(10)
    end

    def create
      saas_stripe_product = Stripe::Product.create(name: "Custom - #{params[:saas_subscription_name]}")
      saas_stripe_annual_price = Stripe::Price.create(
        unit_amount_decimal: params[:saas_annual_amount_in_dollars] / 100.0,
        nickname: 'Annual rate',
        currency: 'usd',
        recurring: {
          interval: 'year'
        }
      )
      saas_stripe_monthly_price = Stripe::Price.create(
        unit_amount_decimal: params[:saas_monthly_amount_in_dollars] / 100.0,
        nickname: 'Monthly rate',
        currency: 'usd',
        recurring: {
          interval: 'month'
        }
      )
      annual_subscription_price_option = SaasFeeSubscriptionPriceOption.create(
        name: "Custom - #{params[:saas_subscription_name]} #{Rails.env.production? ? nil : "- #{Rails.env} -"} Annual rate",
        subscription_package_type: 'custom',
        billing_interval: 'year'
      )
      monthly_subscription_price_option = SaasFeeSubscriptionPriceOption.create(
        name: "Custom - #{params[:saas_subscription_name]} #{Rails.env.production? ? nil : "- #{Rails.env} -"} Monthly rate",
        subscription_package_type: 'custom',
        billing_interval: 'month'
      )
    end
  end
end