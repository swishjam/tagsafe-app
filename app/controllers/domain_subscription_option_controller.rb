class DomainSubscriptionOptionController < LoggedInController
  def edit
    has_payment_method = Stripe::Customer.retrieve(current_domain.stripe_customer_id).invoice_settings.default_payment_method.present?
    stream_modal(
      partial: 'domain_subscription_option/edit',
      locals: { 
        domain_subscription_plan: current_domain.subscription_plan,
        has_payment_method: has_payment_method
      }
    )
  end

  def update
    old_subscription_option = current_domain.subscription_plan&.subscription_option
    new_subscription_option = SubscriptionOption.find(params[:domain][:subscription_option_id])
    if params[:stripe_payment_method_id]
      customer = Stripe::Customer.update(current_domain.stripe_customer_id, {
        invoice_settings: { 
          default_payment_method: params[:stripe_payment_method_id] 
        },
        expand: ['invoice_settings.default_payment_method']
      })
      default_payment_method = customer.invoice_settings.default_payment_method
    else
      default_payment_method = Stripe::Customer.retrieve({ id: current_domain.stripe_customer_id, expand: ['invoice_settings.default_payment_method'] }).invoice_settings.default_payment_method
    end
    new_subscription_option.apply_to_domain(current_domain)
    current_domain.stream_billing_details_updates(domain: current_domain, default_payment_method: default_payment_method)
    stream_modal(
      partial: 'domain_subscription_option/edit',
      locals: { 
        completed: true,
        new_subscription_option: new_subscription_option,
        upgraded: !old_subscription_option || new_subscription_option > old_subscription_option
      }
    )
  end
end