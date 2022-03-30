module Schedule
  class PurgeDomainsGeneratingThirdPartyImpactTrialJob < ApplicationJob
    def perform
      start_time = Time.now
      third_party_impact_trial_domains = Domain.generating_third_party_impact_trial
      Rails.logger.info "Schedule::PurgeDomainsGeneratingThirdPartyImpactTrialJob - Beginning to purge #{third_party_impact_trial_domains.count} Domains that generated third party impact trials....."
      third_party_impact_trial_domains.each(&:destroy_fully!)
      Rails.logger.info "Schedule::PurgeDomainsGeneratingThirdPartyImpactTrialJob - Completed purge in #{start_time - Time.now} seconds."
    end
  end
end