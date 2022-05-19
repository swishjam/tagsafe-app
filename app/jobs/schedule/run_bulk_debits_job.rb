module Schedule
  class RunBulkDebitsJob < ApplicationJob
    def perform
      start = Time.current
      domains = Domain.all
      Rails.logger.info "RunBulkDebitsJob - beginning batch for #{domains.count} Domains"
      domains.each do |domain|
        WalletModerator::UptimeCheckDebiter.new(domain).debit_for_uptime_checks!
        WalletModerator::ReleaseCheckDebiter.new(domain).debit_for_release_checks!
      end
      Rails.logger.info "RunBulkDebitsJob - completed debiting #{domains.count} Domains in #{Time.current - start} seconds."
    end
  end
end