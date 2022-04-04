class SubscriptionPrice < ApplicationRecord
  has_many :subscription_plan_subscription_prices
  has_many :subscription_plans, through: :subscription_plan_subscription_prices

  before_validation :generate_slug
  before_validation :set_price_in_cents_to_stripe_price

  validates_uniqueness_of :slug, scope: :type
  validates_presence_of :stripe_price_id

  def self.DEFAULT
    self.find_by!(slug: 'default')
  end

  private

  def generate_slug
    self.slug = name.gsub(' ', '_').downcase
  end

  def set_price_in_cents_to_stripe_price
    self.price_in_cents = Stripe::Price.retrieve(stripe_price_id).unit_amount_decimal.to_f
  end
end