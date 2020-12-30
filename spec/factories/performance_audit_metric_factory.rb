FactoryBot.define do
  factory :performance_audit_metric do
    association :performance_audit
    association :performance_audit_metric_type
    result { 0 }
  end
end