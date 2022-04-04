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
      locals: { client_secret: setup_intent.client_secret, should_reload: params[:should_reload] }
    )
  end

  def create
    customer = Stripe::Customer.update(current_domain.stripe_customer_id, {
      invoice_settings: { 
        default_payment_method: params[:stripe_payment_method_id] 
      },
      expand: ['invoice_settings.default_payment_method']
    })
    current_domain.update!(stripe_payment_method_id: params[:stripe_payment_method_id])
    current_user.broadcast_notification(message: "Payment method updated.")
    current_domain.stream_billing_details_updates(domain: current_domain, default_payment_method: customer.invoice_settings.default_payment_method)
    stream_modal(partial: 'domain_payment_methods/new', locals: { success_message: 'Default payment method updated.' })
  end
end