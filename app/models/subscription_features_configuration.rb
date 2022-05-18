class SubscriptionFeaturesConfiguration < ApplicationRecord
  belongs_to :domain

  DEFAULTS_FOR_PACKAGE = {
    starter: {
      package_inherited_from: 'starter',
      num_credits_provided_each_month: 10_000,
      has_advance_performance_audit_configurations: false,
      tag_sync_minute_cadence: 1_440, # nightly
      min_release_check_minute_interval: 360,
      data_retention_days: 7
    },
    scale: {
      package_inherited_from: 'scale',
      num_credits_provided_each_month: 100_000,
      has_advance_performance_audit_configurations: false,
      tag_sync_minute_cadence: 360, # every 6 hours
      min_release_check_minute_interval: 60,
      data_retention_days: 45
    },
    pro: {
      package_inherited_from: 'pro',
      num_credits_provided_each_month: 500_000,
      has_advance_performance_audit_configurations: true,
      tag_sync_minute_cadence: 60,
      min_release_check_minute_interval: 5,
      data_retention_days: 90
    }
  }

  def self.create_or_update_for_domain_by_subscription_package(package_type, domain)
    restriction_attrs_for_package = DEFAULTS_FOR_PACKAGE[package_type.to_sym]
    if domain.subscription_features_configuration.present?
      domain.subscription_features_configuration.update!(restriction_attrs_for_package)
    else
      create!(restriction_attrs_for_package.merge(domain: domain))
    end
  end

  def self.FOR_DELINQUENT_SUBSCRIPTION
    @FOR_DELINQUENT_SUBSCRIPTION ||= new(DEFAULTS_FOR_PACKAGE[:starter])
  end

  def min_release_check_minute_interval_in_words
    Util.integer_to_interval_in_words(min_release_check_minute_interval)
  end

  def tag_sync_minute_cadence_in_words
    Util.integer_to_interval_in_words(tag_sync_minute_cadence)
  end
end