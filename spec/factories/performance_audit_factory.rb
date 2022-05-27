FactoryBot.define do
  factory :performance_audit, class: PerformanceAudit  do
    association :audit
    batch_identifier { SecureRandom.hex }
    dom_complete { 100 }
    dom_interactive { 100 }
    first_contentful_paint { 100 }
    script_duration { 100 }
    layout_duration { 100 }
    task_duration { 100 }
    dom_content_loaded { 100 }
    page_trace_s3_url { 'www.aws.com/trace.json' }
    bytes { 100 }
    main_thread_execution_tag_responsible_for { 100 }
    speed_index { 100 }
    perceptual_speed_index { 100 }
    ms_until_first_visual_change { 100 }
    ms_until_last_visual_change { 100 }
    main_thread_blocking_execution_tag_responsible_for { 100 }
    entire_main_thread_execution_ms  { 100 }
    entire_main_thread_blocking_executions_ms { 100 }
    seconds_to_complete { 10 }
    completed_at { 5.minutes.ago }
  end

  factory :individual_performance_audit_with_tag, parent: :performance_audit do
    association :audit
    type { IndividualPerformanceAuditWithTag.to_s }
  end

  factory :individual_performance_audit_without_tag, parent: :performance_audit do
    association :audit
    type { IndividualPerformanceAuditWithoutTag.to_s }
  end

  factory :median_individual_performance_audit_with_tag, parent: :performance_audit do
    association :audit
    type { MedianIndividualPerformanceAuditWithTag.to_s }
  end

  factory :median_individual_performance_audit_without_tag, parent: :performance_audit do
    association :audit
    type { MedianIndividualPerformanceAuditWithoutTag.to_s }
  end

  factory :average_performance_audit_with_tag, parent: :performance_audit do
    association :audit
    type { AveragePerformanceAuditWithTag.to_s }
  end

  factory :average_performance_audit_without_tag, parent: :performance_audit do
    association :audit
    type { AveragePerformanceAuditWithoutTag.to_s }
  end
end