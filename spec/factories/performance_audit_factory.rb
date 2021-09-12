FactoryBot.define do
  factory :delta_performance_audit do
    association :audit
    type { 'DeltaPerformanceAudit' }
  end

  factory :individual_performance_audit_with_tag do
    association :audit
    type { 'IndividualPerformanceAuditWithTag' }
  end

  factory :individual_performance_audit_without_tag do
    association :audit
    type { 'IndividualPerformanceAuditWithoutTag' }
  end
end