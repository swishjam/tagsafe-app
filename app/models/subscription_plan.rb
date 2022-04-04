class SubscriptionPlan < ApplicationRecord
  belongs_to :domain
  has_many :subscription_plan_subscription_prices, dependent: :destroy
  accepts_nested_attributes_for :subscription_plan_subscription_prices
  has_many :subscription_prices, through: :subscription_plan_subscription_prices
  
  scope :current, -> { where(current: true) }

  validates_uniqueness_of :current, scope: :domain_id

  def per_automated_performance_audit_subscription_price
    subscription_prices.find_by(type: PerAutomatedPerformanceAuditSubscriptionPrice.to_s)
  end

  def per_automated_test_run_subscription_price
    subscription_prices.find_by(type: PerAutomatedTestRunSubscriptionPrice.to_s)
  end

  def per_tag_check_subscription_price
    subscription_prices.find_by(type: PerTagCheckSubscriptionPrice.to_s)
  end

  # def subscription_plan_subscription_price_for(subscription_price)
  #   subscription_plan_subscription_prices.find_by(subscription_price: subscription_price)
  # end

  def stripe_subscription_item_id_for(subscription_price_klass)
    subscription_plan_subscription_prices.joins(:subscription_price).find_by(subscription_price: { type: subscription_price_klass.to_s })&.stripe_subscription_item_id
  end

  DELINQUENT_STATUSES = %w[incomplete_expired past_due unpaid]

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
    define_method(:"#{stripe_status}?") { self.status == stripe_status }
  end

  def self.create_default(domain)
    SubscriptionMaintainer::Applier.new(domain).apply_default_subscription_for_domain
  end

  def cancel!
    SubscriptionMaintainer::Applier.new(domain).cancel_current_subscription!
  end

  def delinquent?
    self.class::DELINQUENT_STATUSES.include?(status)
  end
  alias is_delinquent? delinquent?

  def human_status
    status.gsub('_', ' ')
  end

  def update_status_to(new_status)
    unless new_status == status
      update!(status: new_status)
      after_became_delinquent if delinquent?
    end
  end

  def after_became_delinquent
  end
end