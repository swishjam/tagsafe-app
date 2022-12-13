FactoryBot.define do
  factory :performance_audit_calculator do
    association :container
    currently_active { true }
    dom_complete_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:dom_complete_weight] }
    dom_content_loaded_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:dom_content_loaded_weight] }
    dom_interactive_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:dom_interactive_weight] }
    first_contentful_paint_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:first_contentful_paint_weight] }
    layout_duration_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:layout_duration_weight] }
    task_duration_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:task_duration_weight] }
    script_duration_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:script_duration_weight] }
    byte_size_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:byte_size_weight] }
    main_thread_execution_tag_responsible_for_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:main_thread_execution_tag_responsible_for_weight] }
    speed_index_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:speed_index_weight] }
    perceptual_speed_index_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:perceptual_speed_index_weight] }
    ms_until_first_visual_change_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:ms_until_first_visual_change_weight] }
    ms_until_last_visual_change_weight { PerformanceAuditCalculator::DEFAULT_WEIGHTS[:ms_until_last_visual_change_weight] }

    dom_complete_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:dom_complete_score_decrement_amount] }
    dom_content_loaded_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:dom_content_loaded_score_decrement_amount] }
    dom_interactive_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:dom_interactive_score_decrement_amount] }
    first_contentful_paint_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:first_contentful_paint_score_decrement_amount] }
    layout_duration_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:layout_duration_score_decrement_amount] }
    task_duration_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:task_duration_score_decrement_amount] }
    script_duration_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:script_duration_score_decrement_amount] }
    byte_size_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:byte_size_score_decrement_amount] }
    main_thread_execution_tag_responsible_for_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:main_thread_execution_tag_responsible_for_score_decrement_amount] }
    speed_index_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:speed_index_score_decrement_amount] }
    perceptual_speed_index_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:perceptual_speed_index_score_decrement_amount] }
    ms_until_first_visual_change_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:ms_until_first_visual_change_score_decrement_amount] }
    ms_until_last_visual_change_score_decrement_amount { PerformanceAuditCalculator::DEFAULT_DECREMENTS[:ms_until_last_visual_change_score_decrement_amount] }
  end
end