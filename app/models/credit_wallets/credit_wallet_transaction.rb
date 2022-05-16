class CreditWalletTransaction < ApplicationRecord
  belongs_to :credit_wallet
  belongs_to :record_responsible_for_charge, polymorphic: true

  scope :num_credits_used_greater_than, -> (num_credits) { where("credits_used > ?", num_credits) }
  scope :num_credits_used_less_than, -> (num_credits) { where("credits_used < ?", num_credits) }
  scope :debits, -> { num_credits_used_greater_than(0) }
  scope :credits, -> { num_credits_used_less_than(0) }

  validates :reason_for_transaction, inclusion: { in: %w[audit release_checks uptime_checks failed_performance_audit replenishment_purchase gift] }

  class Reasons
    class << self
      %w[audit release_checks uptime_checks failed_performance_audit replenishment_purchase gift].each do |reason|
        define_method(reason.upcase) { reason }
      end
    end
  end

  def is_debit?
    credits_used.positive?
  end

  def is_credit?
    credits_used.negative?
  end
end