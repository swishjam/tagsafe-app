module Admin
  class DomainsController < BaseController
    def index
      @domains = Domain.all.order(:url).page(params[:page] || 1).per(10)
    end

    def show
      @domain = Domain.find_by(uid: params[:uid])
      @next_saas_invoice = Stripe::Invoice.upcoming({ subscription: @domain.current_saas_subscription_plan.stripe_subscription_id, expand: ['lines.data.price.product'] })
      @next_usage_based_invoice = Stripe::Invoice.upcoming({ subscription: @domain.current_usage_based_subscription_plan.stripe_subscription_id, expand: ['lines.data.price.product'] })
    end
  end
end