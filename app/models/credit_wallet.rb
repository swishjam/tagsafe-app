class CreditWallet < ApplicationRecord
  belongs_to :domain
  has_many :transactions, class_name: CreditWalletTransaction.to_s, dependent: :destroy
  
  validates_uniqueness_of :domain_id, scope: :month, message: Proc.new{ |wallet| "already has a wallet for the month of #{wallet.month}" }
  validate :has_enough_credits?

  before_validation :set_credits_used_and_credits_remaining, on: :create
  after_update :create_transaction

  scope :by_month, -> (month_int) { where(month: month_int) }
  scope :for_current_month, -> { by_month(Time.current.month) }
  scope :disabled, -> { where.not(disabled_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }

  DEFAULT_BEGINNING_CREDITS_FOR_PACKAGE = {
    starter: 100_000,
    scale: 500_000,
    pro: 1_000_000
  }

  def self.for(domain, create_if_nil: true, month: Time.current.month)
    domain.credit_wallets.enabled.for_current_month.limit(1).first || 
      create_if_nil ? self.create_for_domain!(domain, month: month) : nil
  end

  def debit!(num_credits)
    self.credits_used += num_credits
    self.credits_remaining -= num_credits
    self.save!
  end

  def credit!(num_credits)
    self.credits_used -= num_credits
    self.credits_remaining += num_credits
    self.save!
  end

  def disable!
    touch(:disabled_at)
  end

  private

  def self.create_for_domain!(domain, month: Time.current.month)
    previous_months_wallet = domain.credit_wallets.by_month(month - 1).limit(1).first
    beginning_credits = previous_months_wallet.present? ? previous_months_wallet.beginning_credits : DEFAULT_BEGINNING_CREDITS_FOR_PACKAGE[domain.current_saas_subscription_plan.package_type.to_sym]
    domain.credit_wallets.create!(month: Time.current.month, beginning_credits: beginning_credits)
  end

  def has_enough_credits?
    return unless credits_remaining < 0
    errors.add(:base, "Cannot debit CreditWallet, only #{credits_remaining_was} credits available.")
  end

  def create_transaction
    return unless saved_changes['credits_remaining'].present?
    num_credits_before_transaction = saved_changes['credits_remaining'][0]
    transactions.create!(
      credits_used: num_credits_before_transaction - credits_remaining,
      num_credits_before_transaction: num_credits_before_transaction,
      num_credits_after_transaction: credits_remaining
    )
  end

  def set_credits_used_and_credits_remaining
    self.credits_used = 0
    self.credits_remaining = self.beginning_credits
  end
end