FactoryBot.define do
  factory :delta_performance_audit do
    association :audit
    association :performance_audit_with_tag
    association :performance_audit_without_tag
    is_outlier { false }
    tagsafe_score { 100 }
    dom_complete_delta { 0 }
    dom_content_loaded_delta { 0 }
    dom_interactive_delta { 0 }
    first_contentful_paint_delta { 0 }
    script_duration_delta { 0 }
    layout_duration_delta { 0 }
    task_duration_delta { 0 }
    bytes { 1 }
    main_thread_execution_tag_responsible_for_delta { 0 }
    speed_index_delta { 0 }
    perceptual_speed_index_delta { 0 }
    ms_until_first_visual_change_delta { 0 }
    ms_until_last_visual_change_delta { 0 }
    main_thread_blocking_execution_tag_responsible_for_delta { 0 }
    entire_main_thread_execution_ms_delta { 0 }
    entire_main_thread_blocking_executions_ms_delta { 0 }
  end

  factory :individual_delta_performance_audit, parent: :delta_performance_audit, class: DeltaPerformanceAudit do
    type { IndividualDeltaPerformanceAudit.to_s }
  end

  factory :median_delta_performance_audit, parent: :delta_performance_audit, class: DeltaPerformanceAudit do
    type { MedianDeltaPerformanceAudit.to_s }
  end

  factory :average_delta_performance_audit, parent: :delta_performance_audit, class: DeltaPerformanceAudit do
    type { AverageDeltaPerformanceAudit.to_s }
  end
end