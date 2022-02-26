FactoryBot.define do
  factory :delta_performance_audit do
    association :audit
    type { 'DeltaPerformanceAudit' }
  end

  factory :individual_performance_audit_with_tag do
    association :audit
    type { 'PerformanceAuditWithTag' }
  end

  factory :individual_performance_audit_without_tag do
    association :audit
    type { 'PerformanceAuditWithoutTag' }
  end
end