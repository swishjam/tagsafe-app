class SubscriptionPrice < ApplicationRecord
  has_many :subscription_items
  has_many :subscription_plans, through: :subscription_items

  before_validation :generate_slug
  before_validation :set_price_in_cents_to_stripe_price

  validates_uniqueness_of :slug, scope: :type
  validates_presence_of :stripe_price_id

  class << self
    attr_accessor :billable_model
  end

  def self.DEFAULT
    self.find_by!(slug: 'default')
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