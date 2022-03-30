class DomainPaymentMethodsController < LoggedInController
  def new
    setup_intent = Stripe::SetupIntent.create(
      customer: current_domain.stripe_customer_id,
      payment_method_types: ['card'],
      # payment_method_types: ['card', 'us_bank_account'],
      usage: 'off_session'
    )
    stream_modal(
      partial: 'domain_payment_methods/new',
      locals: { 
        client_secret: setup_intent.client_secret, 
        subscription_option_to_apply_on_success: params[:subscription_option_id].present? ? SubscriptionOption.find(params[:subscription_option_id]) : nil,
        include_back_button: params[:subscription_option_id].present?
      }
    )
  end

  def create
    customer = Stripe::Customer.update(current_domain.stripe_customer_id, {
      invoice_settings: { 
        default_payment_method: params[:stripe_payment_method_id] 
      },
      expand: ['invoice_settings.default_payment_method']
    })
    current_user.broadcast_notification(message: "Payment method updated.")
    current_domain.stream_billing_details_updates(domain: current_domain, default_payment_method: customer.invoice_settings.default_payment_method)
    stream_modal(partial: 'domain_payment_methods/new', locals: { success_message: 'Default payment method updated.' })
  end
end