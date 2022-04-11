class SettingsController < LoggedInController
  before_action { render_breadcrumbs({ text: 'Settings' }) }
  def tag_management
    @tags = current_domain.tags.joins(:tag_preferences)
                          .order('tag_preferences.tag_check_minute_interval DESC')
                          .order('removed_from_site_at ASC')
                          .order('last_released_at DESC')
  end

  def billing
    # @customer = Stripe::Customer.retrieve({ id: current_domain.stripe_customer_id, expand: ['invoice_settings.default_payment_method'] })
    # @default_payment_method = @customer.invoice_settings.default_payment_method
    @default_payment_method = Stripe::PaymentMethod.retrieve(current_domain.stripe_payment_method_id) unless current_domain.stripe_payment_method_id.nil?
    @next_invoice = Stripe::Invoice.upcoming({ customer: current_domain.stripe_customer_id, expand: ['lines.data.price.product'] })
  end
end