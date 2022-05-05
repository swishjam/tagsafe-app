class SubscriptionFeatureRestriction < ApplicationRecord
  belongs_to :domain

  DEFAULTS_FOR_PACKAGE = {
    starter: {
      max_manual_performance_audits_per_month: 100,
      max_manual_test_runs_per_month: 100,
      max_automated_performance_audits_per_month: 100,
      max_automated_test_runs_per_month: 100,
      uptime_regions_availability: 'none',
      has_advance_performance_audit_configurations: false,
      tag_sync_minute_cadence: 60 * 24, # nightly
      min_release_check_minute_interval: 180,
      data_retention_days: 7
    },
    scale: {
      max_manual_performance_audits_per_month: nil,
      max_manual_test_runs_per_month: nil,
      max_automated_performance_audits_per_month: nil,
      max_automated_test_runs_per_month: nil,
      uptime_regions_availability: 'regional',
      has_advance_performance_audit_configurations: false,
      tag_sync_minute_cadence: 60 * 6, # every 6 hours
      min_release_check_minute_interval: 30,
      data_retention_days: 45
    },
    pro: {
      max_manual_performance_audits_per_month: nil,
      max_manual_test_runs_per_month: nil,
      max_automated_performance_audits_per_month: nil,
      max_automated_test_runs_per_month: nil,
      uptime_regions_availability: 'global',
      has_advance_performance_audit_configurations: true,
      tag_sync_minute_cadence: 60,
      min_release_check_minute_interval: 5,
      data_retention_days: 90
    }
  }

  validates :uptime_regions_availability, inclusion: { in: %w[none regional global] }

  def self.create_default_for_subscription_package(package_type, domain)
    restriction_attrs_for_package = DEFAULTS_FOR_PACKAGE[package_type.to_sym]
    if domain.subscription_feature_restriction.present?
      domain.subscription_feature_restriction.update!(restriction_attrs_for_package)
    else
      create!(restriction_attrs_for_package.merge(domain: domain))
    end
  end
end