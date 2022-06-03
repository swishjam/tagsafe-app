module WalletModerator
  class UptimeCheckBulkDebiter
    def initialize(domain)
      @domain = domain
    end

    def debit_for_uptime_checks!
      Rails.logger.info "WalletModerator::UptimeCheckDebiter - debiting Domain #{@domain.uid} for #{uptime_check_credits_used} credits (#{num_uptime_checks_in_period} UptimeChecks)"
      UptimeChecksBulkDebit.debit!(
        amount: uptime_check_credits_used,
        num_records_for_debited_date_range: num_uptime_checks_in_period,
        credit_wallet: CreditWallet.for_domain(@domain), 
        start_date: start_date_of_upcoming_bulk_debit,
        end_date: Time.current
      )
    end

    private

    def uptime_check_credits_used
      num_uptime_checks_in_period * @domain.feature_prices_in_credits.uptime_check_price
    end

    def num_uptime_checks_in_period
      @num_uptime_checks ||= @domain.uptime_checks.more_recent_than(start_date_of_upcoming_bulk_debit, timestamp_column: :"uptime_checks.executed_at").count
    end

    def start_date_of_upcoming_bulk_debit
      # we should never really debit wallets outside of current month, default to previous month just in case of race condition timing
      most_recent_uptime_debit.present? ? most_recent_uptime_debit.end_date : Time.current.beginning_of_month.last_month
    end

    def most_recent_uptime_debit
      @most_recent_uptime_debit ||= @domain.bulk_debits.where(type: UptimeChecksBulkDebit.to_s).most_recent
    end
  end
end