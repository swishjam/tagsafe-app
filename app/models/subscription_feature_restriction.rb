class SubscriptionFeatureRestriction < ApplicationRecord
  belongs_to :domain

  DEFAULTS_FOR_PACKAGE = {
    starter: {
      package_inherited_from: 'starter',
      manual_performance_audits_included_per_month: 100,
      manual_test_runs_included_per_month: 100,
      automated_performance_audits_included_per_month: 100,
      automated_test_runs_included_per_month: 100,
      release_checks_included_per_month: 1_000,
      uptime_checks_included_per_month: 0,
      has_advance_performance_audit_configurations: false,
      tag_sync_minute_cadence: 1_440, # nightly
      min_release_check_minute_interval: 360,
      data_retention_days: 7
    },
    scale: {
      package_inherited_from: 'scale',
      manual_performance_audits_included_per_month: nil,
      manual_test_runs_included_per_month: nil,
      automated_performance_audits_included_per_month: 2_500,
      automated_test_runs_included_per_month: 5_000,
      release_checks_included_per_month: 50_000,
      uptime_checks_included_per_month: 250_000,
      has_advance_performance_audit_configurations: false,
      tag_sync_minute_cadence: 360, # every 6 hours
      min_release_check_minute_interval: 60,
      data_retention_days: 45
    },
    pro: {
      package_inherited_from: 'pro',
      manual_performance_audits_included_per_month: nil,
      manual_test_runs_included_per_month: nil,
      automated_performance_audits_included_per_month: 5_000,
      automated_test_runs_included_per_month: 10_000,
      release_checks_included_per_month: 100_000,
      uptime_checks_included_per_month: 500_000,
      has_advance_performance_audit_configurations: true,
      tag_sync_minute_cadence: 60,
      min_release_check_minute_interval: 5,
      data_retention_days: 90
    }
  }

  def self.create_default_for_subscription_package(package_type, domain)
    restriction_attrs_for_package = DEFAULTS_FOR_PACKAGE[package_type.to_sym]
    if domain.subscription_feature_restriction.present?
      domain.subscription_feature_restriction.update!(restriction_attrs_for_package)
    else
      create!(restriction_attrs_for_package.merge(domain: domain))
    end
  end

  def self.FOR_DELINQUENT_SUBSCRIPTION
    @FOR_DELINQUENT_SUBSCRIPTION ||= new(DEFAULTS_FOR_PACKAGE[:starter])
  end
end