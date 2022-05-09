class SubscriptionPriceOption < ApplicationRecord
  has_many :subscription_prices
  has_many :subscription_plans, through: :subscription_prices

  before_validation :generate_slug
  before_validation :set_price_in_cents_to_stripe_price

  validates_uniqueness_of :slug, scope: :type
  validates_uniqueness_of :subscription_package_type, scope: [:type, :billing_interval], message: "Cannot create multiple `#{self.to_s}` with the same `subscription_package_type`, `billing_interval`, and `type`."
  validates :stripe_price_id, presence: true, uniqueness: true
  validates :subscription_package_type, inclusion: { in: %w[starter scale pro custom] }
  validates :billing_interval, inclusion: { in: %w[month year] }

  scope :usage_based, -> { where(type: [PerAutomatedPerformanceAuditSubscriptionPrice.to_s, PerAutomatedTestRunSubscriptionPrice.to_s, PerReleaseCheckSubscriptionPrice.to_s]) }
  scope :flat_saas_rate, -> { where.not(type: [PerAutomatedPerformanceAuditSubscriptionPrice.to_s, PerAutomatedTestRunSubscriptionPrice.to_s, PerReleaseCheckSubscriptionPrice.to_s]) }
  scope :by_package_type, -> (package_type) { where(subscription_package_type: package_type) }

  class << self
    attr_accessor :billable_model
  end

  class BillingInterval
    class << self
      %i[month year].each{ |interval| define_method(interval.upcase) { interval} }
    end
  end

  def self.for_subscription_package_and_billing_interval(package_type, billing_interval)
    find_by!(subscription_package_type: package_type, billing_interval: billing_interval)
  end

  private

  def generate_slug
    self.slug = name.gsub(' ', '_').downcase
  end

  def set_price_in_cents_to_stripe_price
    return if self.price_in_cents.present?
    self.price_in_cents = Stripe::Price.retrieve(stripe_price_id).unit_amount_decimal.to_f
  end
end