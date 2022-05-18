class SubscriptionPlan < ApplicationRecord
  belongs_to :domain

  DELINQUENT_STATUSES = %w[incomplete_expired unpaid]

  validates :package_type, inclusion: { in: %w[starter scale pro custom] }

  scope :delinquent, -> { where(status: DELINQUENT_STATUSES) }
  scope :not_delinquent, -> { where.not(status: DELINQUENT_STATUSES) }
  scope :canceled, -> { where(status: 'canceled') }
  scope :not_canceled, -> { where.not(status: 'canceled') }
  scope :trialing, -> { where(status: 'trialing') }

  class Packages
    class << self
      %i[starter scale pro custom].each{ |plan_type| define_method(plan_type.upcase){ plan_type } }
    end
  end

  class BillingIntervals
    class << self
      %i[month year].each{ |interval| define_method(interval.upcase) { interval } }
    end
  end

  %w[starter scale pro custom].each{ |package| define_method(:"#{package}?") { package_type == package } }

  DEFAULT_PACKAGE_AND_BILLING_INTERVAL_AMOUNTS = {
    starter: {
      month: 19_99,
      year: 31_984
    },
    scale: {
      month: 79_99,
      year: 767_90
    },
    pro: {
      month: 299_99,
      year: 2879_90
    }
  }
  
  # Possible values are `incomplete`, `incomplete_expired`, `trialing`, `active`, `past_due`, `canceled`, or `unpaid`.
  # For collection_method=charge_automatically a subscription moves into incomplete if the initial payment attempt fails. A 
  # subscription in this state can only have metadata and default_source updated. Once the first invoice is paid, the 
  # subscription moves into an active state. If the first invoice is not paid within 23 hours, the subscription transitions to 
  # `incomplete_expired`. This is a terminal state, the open invoice will be voided and no further invoices will be generated.

  # A subscription that is currently in a trial period is trialing and moves to active when the trial period is over.

  # If subscription collection_method=charge_automatically it becomes past_due when payment to renew it fails and canceled or unpaid 
  # (depending on your subscriptions settings) when Stripe has exhausted all payment retry attempts.

  # If subscription collection_method=send_invoice it becomes past_due when its invoice is not paid by the due date, and canceled or unpaid 
  # if it is still not paid by an additional deadline after that. Note that when a subscription has a status of unpaid, no subsequent invoices 
  # will be attempted (invoices will be created, but then immediately automatically closed). After receiving updated payment information from a customer, 
  # you may choose to reopen and pay their closed invoices.
  %i[active incomplete incomplete_expired trialing past_due canceled unpaid].each do |stripe_status|
    scope :"#{stripe_status}", -> { where(status: stripe_status) }
    define_method(:"#{stripe_status}?") { self.status == stripe_status.to_s }
  end

  def on_free_trial?
    trialing?
  end
  alias is_on_free_trial? on_free_trial?

  def days_until_free_trial_expires(round = true)
    return nil unless is_on_free_trial?
    exact_days = (free_trial_ends_at - Time.current) / 1.day
    round ? exact_days.floor : exact_days
  end

  def time_left_in_free_trial_in_words
    minutes_left = (free_trial_ends_at - Time.current) / 1.minute
    Util.minutes_to_words(minutes_left)
  end

  def human_package_type
    "#{package_type.capitalize} Plan"
  end

  def cancel!
    SubscriptionMaintainer::Remover.new(domain).cancel_current_subscription!
  end

  def fetch_stripe_subscription
    Stripe::Subscription.retrieve(stripe_subscription_id)
  end

  def delinquent?
    self.class::DELINQUENT_STATUSES.include?(status)
  end
  alias is_delinquent? delinquent?

  def human_status
    status.gsub('_', ' ')
  end
end