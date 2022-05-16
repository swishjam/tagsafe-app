class CreditWalletNotification < ApplicationRecord
  class << self
    attr_accessor :tagsafe_email_klass
  end

  belongs_to :credit_wallet

  validates_uniqueness_of :type, scope: %i[
    credit_wallet_id 
    total_credits_for_month_at_time_of_notification
    credits_used_at_time_of_notification
    credits_remaining_at_time_of_notification
  ], message: Proc.new{ |notification| "A #{notification.type} CreditWalletNotification already exists for CreditWallet #{notification.credit_wallet.uid} total_credits_for_month: #{notification.total_credits_for_month_at_time_of_notification}, credits_used: #{notification.credits_used_at_time_of_notification}, credits_remaining: #{notification.credits_remaining_at_time_of_notification}." }

  after_create :send_emails!

  def self.for_credit_wallet_state(credit_wallet)
    find_by(credit_wallet: credit_wallet, total_credits_for_month_at_time_of_notification: credit_wallet.total_credits_for_month)
  end

  def self.create_for_wallet!(credit_wallet)
    create!(
      credit_wallet: credit_wallet,
      total_credits_for_month_at_time_of_notification: credit_wallet.total_credits_for_month,
      credits_used_at_time_of_notification: credit_wallet.credits_used,
      credits_remaining_at_time_of_notification: credit_wallet.credits_remaining,
      sent_at: Time.current
    )
  end

  private

  def send_emails!
    credit_wallet.domain.admin_domain_users.each do |domain_user|
      self.class.tagsafe_email_klass.new(domain_user.user, credit_wallet).send!
    end
  end
end