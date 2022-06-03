module WalletModerator
  class ReleaseCheckBulkDebiter
    def initialize(domain)
      @domain = domain
    end

    def debit_for_release_checks!
      Rails.logger.info "WalletModerator::ReleaseCheckDebiter - debiting Domain #{@domain.uid} for #{release_check_credits_used} credits (#{num_release_checks_in_period} ReleaseChecks)"
      ReleaseChecksBulkDebit.debit!(
        amount: release_check_credits_used,
        num_records_for_debited_date_range: num_release_checks_in_period,
        credit_wallet: CreditWallet.for_domain(@domain), 
        start_date: start_date_of_upcoming_bulk_debit,
        end_date: Time.current
      )
    end

    private

    def release_check_credits_used
      num_release_checks_in_period * @domain.feature_prices_in_credits.release_check_price
    end

    def num_release_checks_in_period
      @num_release_checks ||= @domain.release_checks.more_recent_than(start_date_of_upcoming_bulk_debit, timestamp_column: :"release_checks.executed_at").count
    end

    def start_date_of_upcoming_bulk_debit
      # we should never really debit wallets outside of current month, default to previous month just in case of race condition timing
      # if it's May 25th, start_date = March 31st, 11:59:59
      most_recent_release_debit.present? ? most_recent_release_debit.end_date : Time.current.beginning_of_month.last_month.last_month.end_of_month
    end

    def most_recent_release_debit
      @most_recent_release_debit ||= @domain.bulk_debits.where(type: ReleaseChecksBulkDebit.to_s).most_recent
    end
  end
end