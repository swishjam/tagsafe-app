module Admin
  class SubscriptionPricesController < BaseController
    def index
      @subscription_price_options = SubscriptionPriceOption.all.includes(:subscription_prices).order(:subscription_package_type).page(params[:page] || 1).per(10)
    end

    def new
      @stripe_products = Stripe::Product.list(active: true)
    end

    def create
      saas_stripe_annual_price = Stripe::Price.create(
        product: params[:saas_stripe_product_id],
        unit_amount_decimal: params[:annual_saas_subscription_fee].to_f / 100.0,
        nickname: 'Annual rate',
        currency: 'usd',
        recurring: {
          interval: 'year'
        }
      )
      saas_stripe_monthly_price = Stripe::Price.create(
        unit_amount_decimal: params[:monthly_saas_subscription_fee].to_f / 100.0,
        nickname: 'Monthly rate',
        currency: 'usd',
        recurring: {
          interval: 'month'
        }
      )
      annual_subscription_price_option = SaasFeeSubscriptionPriceOption.create(
        name: "Custom - #{params[:saas_subscription_name]} #{Rails.env.production? ? nil : "- #{Rails.env} -"} Annual rate",
        subscription_package_type: 'custom',
        billing_interval: 'year',
        stripe_price_id: saas_stripe_annual_price.id
      )
      monthly_subscription_price_option = SaasFeeSubscriptionPriceOption.create(
        name: "Custom - #{params[:saas_subscription_name]} #{Rails.env.production? ? nil : "- #{Rails.env} -"} Monthly rate",
        subscription_package_type: 'custom',
        billing_interval: 'month',
        stripe_price_id: saas_stripe_monthly_price.id
      )
    end
  end
end