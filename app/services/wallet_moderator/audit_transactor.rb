module WalletModerator
  class AuditTransactor
    def initialize(audit)
      @audit = audit
    end

    def debit_wallet!
      return if @audit.performance_audit_failed?
      price_calculator = PriceCalculators::Audits.new(@audit)
      [
        CreditWalletTransaction::Reasons.AUTOMATED_PERFORMANCE_AUDIT,
        CreditWalletTransaction::Reasons.MANUAL_PERFORMANCE_AUDIT,
        CreditWalletTransaction::Reasons.AUTOMATED_TEST_RUN,
        CreditWalletTransaction::Reasons.MANUAL_TEST_RUN,
        CreditWalletTransaction::Reasons.PERFORMANCE_AUDIT_RECORDING,
        CreditWalletTransaction::Reasons.PERFORMANCE_AUDIT_FILMSTRIP,
        CreditWalletTransaction::Reasons.PERFORMANCE_AUDIT_RESOURCES_WATERFALL
      ].each do |debit_reason|
        num_credits_used_for_feature = price_calculator.price_for(debit_reason)
        wallet.debit!(num_credits_used_for_feature, record_responsible_for_debit: @audit, reason: debit_reason)
      end
    end

    def credit_wallet!(force: false)
      return unless wallet.present? && (@audit.performance_audit_failed? || force)
      performance_audit_price = PriceCalculators::Audits.new(@audit).cumulative_price_for_performance_audit
      wallet.credit!(performance_audit_price, record_responsible_for_credit: @audit, reason: CreditWalletTransaction::Reasons.FAILED_PERFORMANCE_AUDIT)
    end

    private

    def wallet
      @wallet ||= @audit.domain.credit_wallet_for_current_month_and_year
    end
  end
end