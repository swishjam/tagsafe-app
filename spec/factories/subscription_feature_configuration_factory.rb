FactoryBot.define do
  factory :subscription_features_configuration, class: SubscriptionFeaturesConfiguration do
    association :domain
    package_inherited_from { 'custom' }
    num_credits_provided_each_month { 500_000 }
    has_advance_performance_audit_configurations { true }
    tag_sync_minute_cadence { 60 }
    min_release_check_minute_interval { 5 }
    data_retention_days { 90 }
  end
end