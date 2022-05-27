class CreditWallet < ApplicationRecord
  belongs_to :domain
  belongs_to :subscription_plan, optional: true
  has_many :bulk_debits, dependent: :destroy
  has_many :release_checks_bulk_debits
  has_many :uptime_checks_bulk_debits
  has_many :transactions, class_name: CreditWalletTransaction.to_s, dependent: :destroy
  has_many :notifications, class_name: CreditWalletNotification.to_s, dependent: :destroy
  has_many :low_credit_notifications, class_name: LowCreditsCreditWalletNotification.to_s
  has_many :no_credit_notifications, class_name: NoCreditsCreditWalletNotification.to_s
  
  validates_uniqueness_of :domain_id, scope: :month, message: Proc.new{ |wallet| "already has a wallet for the month of #{wallet.month}" }, unless: :disabled?
  validate :credits_used_and_credits_remaining_match_total_credits_for_month

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
    wallet ||= generate_new_wallet(domain) if create_if_nil
    wallet
  end

  def debit!(num_credits, record_responsible_for_debit: nil, reason:)
    num_credits_remaining_before_debit = self.credits_remaining
    self.credits_used += num_credits
    self.credits_remaining -= num_credits
    self.save!
    transactions.create!(
      record_responsible_for_charge: record_responsible_for_debit,
      credits_used: num_credits,
      num_credits_before_transaction: num_credits_remaining_before_debit,
      num_credits_after_transaction: credits_remaining,
      reason_for_transaction: reason
    )
  end

  def credit!(num_credits, record_responsible_for_credit: nil, reason:)
    num_credits_remaining_before_credit = self.credits_remaining
    self.credits_used -= num_credits unless INCREASABLE_CREDITS_FOR_MONTH_REASONS.include?(reason)
    self.credits_remaining += num_credits
    self.total_credits_for_month += num_credits if INCREASABLE_CREDITS_FOR_MONTH_REASONS.include?(reason)
    self.save!
    transactions.create!(
      record_responsible_for_charge: record_responsible_for_credit,
      credits_used: num_credits * -1,
      num_credits_before_transaction: num_credits_remaining_before_credit,
      num_credits_after_transaction: credits_remaining,
      reason_for_transaction: reason
    )
  end

  def has_credits?
    credits_remaining > 0
  end

  def disable!
    touch(:disabled_at)
  end

  def disabled?
    disabled_at.present?
  end

  def percent_used
    (credits_used / total_credits_for_month) * 100
  end

  private

  def self.generate_new_wallet(domain)
    if domain.subscription_features_configuration.nil?
      raise CreditWalletErrors::DomainHasNoSusbscriptionFeaturesConfiguration, <<~ERR
        Cannot create `CreditWallet` for #{domain.uid} because it does not have a `SubscriptionFeaturesConfiguration`. 
        This can happen if an `Audit` has completed before they select a `SubscriptionPlan`.
      ERR
    end
    domain.credit_wallets.create!(month: Time.current.month, total_credits_for_month: domain.subscription_features_configuration.num_credits_provided_each_month)
  rescue CreditWalletErrors::DomainHasNoSusbscriptionFeaturesConfiguration => e
    Rails.logger.error(e.inspect)
    Sentry.capture_exception(e)
  end

  def set_credits_used_and_credits_remaining
    self.credits_used = 0 unless self.credits_used.present?
    self.credits_remaining = self.total_credits_for_month unless self.credits_remaining.present?
  end

  def credits_used_and_credits_remaining_match_total_credits_for_month
    if (credits_used + credits_remaining).round != total_credits_for_month
      errors.add(:base, "CreditWallet mismatch, credits used (#{credits_used.round(2)}) + credits remaining (#{credits_remaining.round(2)}) does not equal total credits for month #{total_credits_for_month}")
    end
  end
end