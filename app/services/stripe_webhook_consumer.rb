class StripeWebhookConsumer
  EVENT_TYPE_METHOD_DICTIONARY = {
    :'invoice.marked_uncollectible' => :invoice_marked_uncollectible,
    :'invoice.payment_failed' => :invoice_payment_failed,
    :'invoice.payment_succeeded' => :invoice_payment_succeeded,
    :'invoice.payment_action_required' => :invoice_payment_action_required,
    :'invoice.upcoming' => :invoice_upcoming,
    :'customer.subscription.updated' => :customer_subscription_updated
  }

  def initialize(stripe_event)
    @stripe_event = stripe_event
  end

  def process_webhook_event!
    method = EVENT_TYPE_METHOD_DICTIONARY[@stripe_event['type'].to_sym]
    if method
      send(method)
    else
      Rails.logger.warn "Received unknown Stripe Event type of #{@stripe_event['type']}"
    end
  end

  private

  # Occurs whenever an invoice payment attempt fails, due either to a declined payment or to the lack of a stored payment method.
  def invoice_payment_failed
    Rails.logger.info "StripeWebhookConsumer Invoice Payment Failed!"
  end

  # Occurs whenever an invoice payment attempt succeeds or an invoice is marked as paid out-of-band.
  def invoice_payment_succeeded
    Rails.logger.info "StripeWebhookConsumer Invoice Payment Paid!"
  end

  # Occurs whenever an invoice payment attempt requires further user action to complete.
  def invoice_payment_action_required
    Rails.logger.info "StripeWebhookConsumer Invoice Payment Action Required!"
  end

  # Occurs X number of days before a subscription is scheduled to create an invoice that is automatically charged—where X is determined by your 
  # subscriptions settings (https://dashboard.stripe.com/account/billing/automatic). Note: The received Invoice object will not have an invoice ID.
  def invoice_upcoming
    Rails.logger.info "StripeWebhookConsumer Invoice is Upcoming!"
  end

  # Occurs whenever an invoice is marked uncollectible.
  def invoice_marked_uncollectible
    Rails.logger.info "StripeWebhookConsumer Invoice Marked as Uncollectible!"
  end

  # Occurs whenever a subscription changes (e.g., switching from one plan to another, or changing the status from trial to active).
  def customer_subscription_updated
    stripe_customer_id = @stripe_event.dig('data', 'object', 'customer')
    domain = Domain.find_by(stripe_customer_id: stripe_customer_id)
    if domain.nil?
      Rails.logger.error "Cannot find Domain for Stripe Customer ID #{stripe_customer_id}, Stripe Subscription ID #{@stripe_event.dig('data', 'object', 'id')}"
    else
      subscription_status = @stripe_event.dig('data', 'object', 'status')
      domain.current_subscription_plan.update_status_to(subscription_status)
    end
  end
end