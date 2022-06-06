class StripeWebhookConsumer
  EVENT_TYPE_METHOD_DICTIONARY = {
    :'customer.subscription.deleted' => :'subscription_ended',
    :'customer.subscription.trial_will_end' => :'free_trial_will_end',
    :'invoice.marked_uncollectible' => :invoice_marked_uncollectible,
    :'invoice.payment_failed' => :invoice_payment_failed,
    :'invoice.payment_succeeded' => :invoice_payment_succeeded,
    # :'invoice.payment_action_required' => :invoice_payment_action_required,
    # :'invoice.upcoming' => :invoice_upcoming,
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
    subscription_plan.domain.admin_domain_users.each do |domain_user|
      TagsafeEmail::FreeTrialWillEnd.new(domain_user.user, subscription_plan).send!
    end
  end

  # Occurs whenever an invoice payment attempt fails, due either to a declined payment or to the lack of a stored payment method.
  def invoice_payment_failed
    Rails.logger.info "StripeWebhookConsumer Invoice Payment Failed!"
    subscription_plan.domain.admin_domain_users.each do |domain_user| 
      TagsafeEmail::PaymentFailed.new(
        user: domain_user.user, 
        subscription_plan: subscription_plan,
        attempt_count: stripe_object.dig('attempt_count'),
        next_attempt_datetime: stripe_object.dig('next_payment_attempt').present? ? Time.at(stripe_object.dig('next_payment_attempt')).to_datetime : nil
      ).send!
    end
  end

  def invoice_payment_succeeded
    return if stripe_object.dig('total').zero?
    Rails.logger.info "StripeWebhookConsumer Invoice Payment Succeeded!"
    subscription = Stripe::Subscription.retrieve(stripe_object.dig('subscription'))
    subscription_plan.domain.admin_domain_users.each do |domain_user|
      TagsafeEmail::PaymentSucceeded.new(
        user: domain_user.user, 
        subscription_plan: subscription_plan,
        stripe_invoice_amount: stripe_object.dig('total'),
        stripe_invoice_start_date: subscription.current_period_start,
        stripe_invoice_end_date: subscription.current_period_end
      ).send!
    end
  end

  # Occurs whenever an invoice is marked uncollectible.
  def invoice_marked_uncollectible
    Rails.logger.info "StripeWebhookConsumer Invoice Marked as Uncollectible!"
    # CreditWallet.for_domain(subscription_plan.domain).disable!
    subscription_plan.domain.admin_domain_users.each do |domain_user| 
      TagsafeEmail::SubscriptionBecameDelinquent.new(domain_user.user).send!
    end
  end

  # Occurs whenever a subscription changes (e.g., switching from one plan to another, or changing the status from trial to active).
  def customer_subscription_updated
    Rails.logger.info "StripeWebhookConsumer Subscription Updated for #{subscription_plan.stripe_subscription_id}"
    subscription_plan.update!(
      amount: stripe_object.dig('plan', 'amount'),
      status: stripe_object.dig('status'), 
      free_trial_ends_at: stripe_object.dig('trial_end') ? Time.at(stripe_object.dig('trial_end')).to_datetime : nil
    )
  end

  def subscription_ended
    Rails.logger.info "StripeWebhookConsumer Subscription ended for #{subscription_plan.stripe_subscription_id}"
    subscription_plan.domain.admin_domain_users.each do |domain_user|
      TagsafeEmail::SubscriptionCanceled.new(domain_user.user, subscription_plan).send!
    end
  end

  def subscription_plan
    @subscription_plan ||= begin
      stripe_subscription_id = case stripe_object.dig('object')
                                when 'subscription' then stripe_object.dig('id')
                                when 'invoice' then stripe_object.dig('subscription')
                                else 
                                  raise "Dont know how to find SubscriptionPlan for a #{stripe_object.dig('object')} Stripe Event object"
                                end
      SubscriptionPlan.find_by!(stripe_subscription_id: stripe_subscription_id)
    end
  end

  def stripe_object
    stripe_event.dig('data', 'object') || {}
  end

  # # Occurs whenever an invoice payment attempt succeeds or an invoice is marked as paid out-of-band.
  # def invoice_payment_succeeded
  #   Rails.logger.info "StripeWebhookConsumer Invoice Payment Paid!"
  # end

  # # Occurs whenever an invoice payment attempt requires further user action to complete.
  # def invoice_payment_action_required
  #   Rails.logger.info "StripeWebhookConsumer Invoice Payment Action Required!"
  # end

  # # Occurs X number of days before a subscription is scheduled to create an invoice that is automatically charged—where X is determined by your 
  # # subscriptions settings (https://dashboard.stripe.com/account/billing/automatic). Note: The received Invoice object will not have an invoice ID.
  # def invoice_upcoming
  #   Rails.logger.info "StripeWebhookConsumer Invoice is Upcoming!"
  # end
end