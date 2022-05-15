class CreditWalletTransaction < ApplicationRecord
  belongs_to :credit_wallet
  # release checks and uptime checks are currently debited in bulk, therefore cant associate it
  belongs_to :record_responsible_for_charge, polymorphic: true, optional: true

  scope :num_credits_used_greater_than, -> (num_credits) { where("credits_used > ?", num_credits) }
  scope :num_credits_used_less_than, -> (num_credits) { where("credits_used < ?", num_credits) }
  scope :debits, -> { num_credits_used_greater_than(0) }
  scope :credits, -> { num_credits_used_less_than(0) }

  validates :reason_for_transaction, inclusion: { in: %w[audit release_check uptime_check purchase gift] }

  # currently can have one debit, one credit
  # validates_uniqueness_of :record_responsible_for_charge_id

  class Reasons
    class << self
      %i[audit release_checks uptime_checks failed_performance_audit replenish gift].each do |reason|
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