module Schedule
  class DebitWalletsForUptimeAndReleaseChecksJob < ApplicationJob
    def perform
      start = Time.current
      beginning_of_previous_hour = 1.hour.ago.beginning_of_hour
      domains = Domain.all
      Rails.logger.info "DebitWalletsForUptimeAndReleaseChecksJob - beginning batch for #{domains.count} Domains, for timeframe #{beginning_of_previous_hour} - #{beginning_of_previous_hour.end_of_hour}"
      domains.each do |domain|
        wallet = CreditWallet.for(domain, month: beginning_of_previous_hour.month)
        feature_prices = domain.feature_prices_in_credits
        
        num_uptime_checks = domain.uptime_checks
                                    .more_recent_than_or_equal_to(beginning_of_previous_hour, timestamp_column: :"uptime_checks.executed_at")
                                    .older_than_or_equal_to(beginning_of_previous_hour.end_of_hour, timestamp_column: :"uptime_checks.executed_at")
                                    .count
        uptime_check_credits_used = num_uptime_checks * feature_prices.uptime_check_price
        Rails.logger.info "DebitWalletsForUptimeAndReleaseChecksJob - debiting Domain #{domain.uid} for #{uptime_check_credits_used} credits (#{num_uptime_checks} UptimeChecks)"
        wallet.debit!(uptime_check_credits_used, record_responsible_for_debit: nil, reason: CreditWalletTransaction::Reasons.UPTIME_CHECKS) unless uptime_check_credits_used.zero?

        num_release_checks = domain.release_checks
                                      .more_recent_than_or_equal_to(beginning_of_previous_hour, timestamp_column: :"release_checks.executed_at")
                                      .older_than_or_equal_to(beginning_of_previous_hour.end_of_hour, timestamp_column: :"release_checks.executed_at")
                                      .count
        release_check_credits_used = num_release_checks * feature_prices.release_check_price
        Rails.logger.info "DebitWalletsForUptimeAndReleaseChecksJob - debiting Domain #{domain.uid} for #{release_check_credits_used} credits (#{num_release_checks} ReleaseChecks)"
        wallet.debit!(release_check_credits_used, record_responsible_for_debit: nil, reason: CreditWalletTransaction::Reasons.RELEASE_CHECKS) unless release_check_credits_used.zero?
      end
      Rails.logger.info "DebitWalletsForUptimeAndReleaseChecksJob - completed debiting #{domains.count} Domains in #{Time.current - start} seconds."
    end
  end
end