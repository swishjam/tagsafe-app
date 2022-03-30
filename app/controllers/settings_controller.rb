class SettingsController < LoggedInController
  def tag_management
    @tags = current_domain.tags.joins(:tag_preferences)
                          .order('tag_preferences.enabled DESC')
                          .order('removed_from_site_at ASC')
                          .order('last_released_at DESC')
  end

  def billing
    @customer = Stripe::Customer.retrieve({ id: current_domain.stripe_customer_id, expand: ['invoice_settings.default_payment_method'] })
    @default_payment_method = @customer.invoice_settings.default_payment_method
    @next_invoice = current_domain.selected_subscription_option.basic? ? nil : Stripe::Invoice.upcoming({ customer: current_domain.stripe_customer_id, expand: ['lines.data.price.product'] })
  end
end