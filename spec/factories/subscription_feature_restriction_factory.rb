FactoryBot.define do
  factory :subscription_feature_restriction_zero_features, class: SubscriptionFeatureRestriction do
    association :domain
    package_inherited_from { 'custom' }
    manual_performance_audits_included_per_month { 0 }
    manual_test_runs_included_per_month { 0 }
    automated_performance_audits_included_per_month { 0 }
    automated_test_runs_included_per_month { 0 }
    uptime_checks_included_per_month { 0 }
    release_checks_included_per_month { 0 }
    min_release_check_minute_interval { 0 }
    tag_sync_minute_cadence { 0 }
    has_advance_performance_audit_configurations { false }
    data_retention_days { 0 }
  end
end