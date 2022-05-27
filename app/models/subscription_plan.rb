class SubscriptionPlan < ApplicationRecord
  belongs_to :domain
  has_many :credit_wallets, dependent: :destroy

  DELINQUENT_STATUSES = %w[incomplete_expired unpaid]

  validates :package_type, inclusion: { in: %w[starter scale pro custom] }

  scope :delinquent, -> { where(status: DELINQUENT_STATUSES) }
  scope :not_delinquent, -> { where.not(status: DELINQUENT_STATUSES) }
  scope :canceled, -> { where(status: 'canceled') }
  scope :not_canceled, -> { where.not(status: 'canceled') }
  scope :trialing, -> { where(status: 'trialing') }

  after_update :send_updated_subscription_email_if_necessary

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
      month: 19_00,
      year: 182_40
    },
    scale: {
      month: 79_00,
      year: 758_40
    },
    pro: {
      month: 299_00,
      year: 2879_90
    }
  }

  def self.price_for(package:, billing_interval:, friendly: false, display_as_monthly: false)
    amt_in_cents = DEFAULT_PACKAGE_AND_BILLING_INTERVAL_AMOUNTS[package.to_sym][billing_interval.to_sym]
    if friendly
      if display_as_monthly && billing_interval.to_sym == BillingIntervals.YEAR
        amt = amt_in_cents / 100.0 / 12
        decimals = (amt % 1).zero? ? 0 : 2
        "$#{sprintf("%.#{decimals}f", amt)}"
      else
        amt = amt_in_cents / 100.0
        decimals = (amt % 1).zero? ? 0 : 2
        "$#{sprintf("%.#{decimals}f", amt)}"
      end
    else
      amt_in_cents
    end
  end
  
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

  def billing_interval_with_ly
    case billing_interval
    when 'month' then 'monthly'
    when 'year' then 'annually'
    end
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

  private

  # def update_domains_credit_wallet
  #   domains_wallet = CreditWallet.for_domain(domain, create_if_nil: false)
  #   if domains_wallet && domains_wallet.subscription_plan_id.nil?
  #     domains_wallet.update!(subscription_plan: self)
  #   elsif domains_wallet.nil? || domains_wallet && domains_wallet.subscription_plan != self
  #     CreditWallet.for_subscription_plan(self)
  #   end
  # end

  def send_updated_subscription_email_if_necessary
    if saved_changes['amount']
      next_invoice = Stripe::Invoice.upcoming(subscription: stripe_subscription_id)
      domain.admin_domain_users.each do |domain_user|
        TagsafeEmail::SubscriptionPlanUpdated.new(
          domain_user.user,
          self,
          previous_amount: saved_changes['amount'][0],
          new_amount: amount,
          next_payment_amount: next_invoice.amount_due,
          next_payment_date: Time.at(next_invoice.next_payment_attempt).strftime("%m/%d/%y @ %l:%M %P %Z")
        ).send!
      end
    end
  end
end