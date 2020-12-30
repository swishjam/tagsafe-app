FactoryBot.define do
  factory :delta_performance_audit do
    association :audit
    type { 'DeltaPerformanceAudit' }
  end

  factory :performance_audit_with_tag do
    association :audit
    type { 'PerformanceAuditWithTag' }
  end
end