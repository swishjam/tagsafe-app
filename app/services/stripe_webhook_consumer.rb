class StripeWebhookConsumer
  EVENT_TYPE_METHOD_DICTIONARY = {
    :'customer.subscription.trial_will_end' => :'free_trial_will_end',
    :'invoice.marked_uncollectible' => :invoice_marked_uncollectible,
    :'invoice.payment_failed' => :invoice_payment_failed,
    :'invoice.payment_succeeded' => :invoice_payment_succeeded,
    :'invoice.payment_action_required' => :invoice_payment_action_required,
    :'invoice.upcoming' => :invoice_upcoming,
    :'customer.subscription.updated' => :customer_subscription_updated
  }

  attr_accessor :stripe_event

  def initialize(stripe_event)
    @stripe_event = stripe_event
  end

  def process_webhook_event!
    method = EVENT_TYPE_METHOD_DICTIONARY[stripe_event['type'].to_sym]
    if method
      send(method)
    else
      Rails.logger.warn "Received unknown Stripe Event type of #{stripe_event['type']}"
    end
  end

  private
  
  # Occurs three days before a subscription's trial period is scheduled to end, or when a trial is ended immediately (using trial_end=now).
  def free_trial_will_end
    Rails.logger.info "StripeWebhookConsumer free trial ending soon!"
    subscription_plan = SubscriptionPlan.find_by!(stripe_subscription_id: stripe_event.dig('data', 'object', 'id'))
    # because we have two subscriptions at all times, assume they each have the same free trial period
    # use the UsageBasedSubscriptionPlan because that is gauranteed to be the Subscription with the lowest cadence (monthly)
    # and to avoid sending two emails each time.
    return if subscription_plan.is_a?(SaasSubscriptionPlan)
    # todo: only send to UserAdmins
    subscription_plan.domain.users.each do |user|
      TagsafeEmail::FreeTrialWillEnd.new(user, subscription_plan).send!
    end
  end

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
    stripe_subscription_id = stripe_event.dig('data', 'object', 'id')
    Rails.logger.info "StripeWebhookConsumer Subscription Updated for #{stripe_subscription_id}"
    subscription_plan = SubscriptionPlan.find_by!(stripe_subscription_id: stripe_subscription_id)
    subscription_status = stripe_event.dig('data', 'object', 'status')
    subscription_plan.update_status_to(subscription_status)
  end
end