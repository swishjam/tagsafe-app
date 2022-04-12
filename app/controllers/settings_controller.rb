class SettingsController < LoggedInController
  before_action { render_breadcrumbs({ text: 'Settings' }) }
  def tag_management
    @tags = current_domain.tags.joins(:tag_preferences)
                          .order('tag_preferences.tag_check_minute_interval DESC')
                          .order('removed_from_site_at ASC')
                          .order('last_released_at DESC')
                          .page(params[:page]).per(params[:per_page] || 10)
  end

  def billing
    unless current_domain.stripe_payment_method_id.nil?
      @default_payment_method = Stripe::PaymentMethod.retrieve(current_domain.stripe_payment_method_id)
      @next_invoice = Stripe::Invoice.upcoming({ customer: current_domain.stripe_customer_id, expand: ['lines.data.price.product'] })
    end
  end
end