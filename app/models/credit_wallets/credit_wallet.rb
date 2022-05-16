class CreditWallet < ApplicationRecord
  belongs_to :domain
  has_many :bulk_debits, dependent: :destroy
  has_many :release_checks_bulk_debits
  has_many :uptime_checks_bulk_debits
  has_many :transactions, class_name: CreditWalletTransaction.to_s, dependent: :destroy
  has_many :notifications, class_name: CreditWalletNotification.to_s, dependent: :destroy
  has_many :low_credit_notifications, class_name: LowCreditsCreditWalletNotification.to_s
  has_many :no_credit_notifications, class_name: NoCreditsCreditWalletNotification.to_s
  
  validates_uniqueness_of :domain_id, scope: :month, message: Proc.new{ |wallet| "already has a wallet for the month of #{wallet.month}" }

  before_validation :set_credits_used_and_credits_remaining, on: :create

  after_update { WalletModerator::Notifications.new(self).send_change_in_credits_notifications }

  scope :by_month, -> (month_int) { where(month: month_int) }
  scope :for_current_month, -> { by_month(Time.current.month) }
  scope :disabled, -> { where.not(disabled_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }
  scope :has_credits_remaining, -> { for_current_month.where('credits_remaining > 0') }

  INCREASABLE_CREDITS_FOR_MONTH_REASONS = [CreditWalletTransaction::Reasons.REPLENISHMENT_PURCHASE, CreditWalletTransaction::Reasons.GIFT]
  DEFAULT_BEGINNING_CREDITS_FOR_PACKAGE = {
    starter: 100_000,
    scale: 500_000,
    pro: 1_000_000
  }

  def self.for_domain(domain, create_if_nil: true, month: Time.current.month)
    wallet = domain.credit_wallets.enabled.for_current_month.limit(1).first
    wallet ||= domain.credit_wallets.create!(month: month, total_credits_for_month: domain.subscription_features_configuration.num_credits_provided_each_month) if create_if_nil
    wallet
  end

  def debit!(num_credits, record_responsible_for_debit: nil, reason:)
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

  def credit!(num_credits, record_responsible_for_credit: nil, reason:)
    num_credits_remaining_before_credit = self.credits_remaining
    self.credits_used -= num_credits
    self.credits_remaining += num_credits
    self.save!
    transaction = create_transaction!(
      num_credits_before_transaction: num_credits_remaining_before_credit,
      record_responsible_for_charge: record_responsible_for_credit, 
      reason: reason
    )
    update_column(:total_credits_for_month, total_credits_for_month + num_credits) if INCREASABLE_CREDITS_FOR_MONTH_REASONS.include?(reason)
    transaction
  end

  def has_credits?
    credits_remaining > 0
  end

  def disable!
    touch(:disabled_at)
  end

  def percent_used
    (credits_used / total_credits_for_month) * 100
  end

  private

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
    self.credits_remaining = self.total_credits_for_month
  end
end