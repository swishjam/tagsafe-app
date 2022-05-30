class CreditWalletTransaction < ApplicationRecord
  belongs_to :credit_wallet
  belongs_to :record_responsible_for_charge, polymorphic: true

  scope :num_credits_used_greater_than, -> (num_credits) { where("credits_used > ?", num_credits) }
  scope :num_credits_used_less_than, -> (num_credits) { where("credits_used < ?", num_credits) }
  scope :debits, -> { num_credits_used_greater_than(0) }
  scope :credits, -> { num_credits_used_less_than(0) }

  validates :reason_for_transaction, inclusion: { in: %w[          
    automated_performance_audit
    automated_test_run
    manual_performance_audit
    manual_test_run
    performance_audit_recording
    performance_audit_filmstrip
    performance_audit_resources_waterfall
    uptime_checks
    release_checks
    failed_performance_audit 
    replenishment_purchase
    gift
  ] }

  class Reasons
    DEBITS = %w[        
      automated_performance_audit
      automated_test_run
      manual_performance_audit
      manual_test_run
      performance_audit_recording
      performance_audit_filmstrip
      performance_audit_resources_waterfall
      uptime_checks
      release_checks
    ]
    CREDITS = %w[failed_performance_audit replenishment_purchase gift]
    class << self
      def CREDITS
        self::CREDITS
      end
      
      def DEBITS
        self::DEBITS
      end

      DEBITS.concat(CREDITS).each do |reason|
        define_method(reason.upcase) { reason }
      end
    end
  end

  def is_debit?
    credits_used.positive?
  end
  alias debit? is_debit?

  def is_credit?
    credits_used.negative?
  end
  alias credit? is_credit?

  def human_reason
    reason_for_transaction.split('_').map(&:capitalize!).join(' ')
  end
end