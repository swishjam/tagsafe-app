class CreditWallet < ApplicationRecord
  belongs_to :domain
  has_many :transactions, class_name: CreditWalletTransaction.to_s, dependent: :destroy
  
  validates_uniqueness_of :domain_id, scope: :month, message: Proc.new{ |wallet| "already has a wallet for the month of #{wallet.month}" }
  # validate :has_enough_credits?

  before_validation :set_credits_used_and_credits_remaining, on: :create

  after_update :send_low_or_no_credits_emails_if_necessary

  scope :by_month, -> (month_int) { where(month: month_int) }
  scope :for_current_month, -> { by_month(Time.current.month) }
  scope :disabled, -> { where.not(disabled_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :has_credits_remaining, -> { for_current_month.where('credits_remaining > 0') }

  DEFAULT_BEGINNING_CREDITS_FOR_PACKAGE = {
    starter: 100_000,
    scale: 500_000,
    pro: 1_000_000
  }

  def self.for(domain, create_if_nil: true, month: Time.current.month)
    wallet = domain.credit_wallets.enabled.for_current_month.limit(1).first
    wallet ||= domain.credit_wallets.create!(month: month, beginning_credits: domain.subscription_features_configuration.num_credits_provided_each_month) if create_if_nil
    wallet
  end

  def debit!(num_credits, record_responsible_for_debit:, reason:)
    num_credits_remaining_before_debit = self.credits_remaining
    self.credits_used += num_credits
    self.credits_remaining -= num_credits
    self.save!
    create_transaction!(
      num_credits_before_transaction: num_credits_remaining_before_debit,
      record_responsible_for_charge: record_responsible_for_debit, 
      reason: reason
    )
  end

  def credit!(num_credits, record_responsible_for_credit:, reason:)
    num_credits_remaining_before_credit = self.credits_remaining
    self.credits_used -= num_credits
    self.credits_remaining += num_credits
    self.save!
    create_transaction!(
      num_credits_before_transaction: num_credits_remaining_before_credit,
      record_responsible_for_charge: record_responsible_for_credit, 
      reason: reason
    )
  end

  def has_credits?
    credits_remaining > 0
  end

  def disable!
    touch(:disabled_at)
  end

  def percent_used
    (credits_used / beginning_credits) * 100
  end

  private

  def send_low_or_no_credits_emails_if_necessary    
  end

  def create_transaction!(record_responsible_for_charge:, num_credits_before_transaction:, reason:)
    transactions.create!(
      record_responsible_for_charge: record_responsible_for_charge,
      credits_used: num_credits_before_transaction - credits_remaining,
      num_credits_before_transaction: num_credits_before_transaction,
      num_credits_after_transaction: credits_remaining,
      reason_for_transaction: reason
    )
  end

  def set_credits_used_and_credits_remaining
    self.credits_used = 0
    self.credits_remaining = self.beginning_credits
  end
end