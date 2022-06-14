class PerformanceAuditExceededThresholdAlertConfiguration < AlertConfiguration
  self.user_facing_alert_name = 'Performance metric exceeded threshold'
  self.user_facing_alert_description = 'An alert will be triggered anytime a tag exceeds a specified performance metric.'

  serialize :trigger_rules, Serializers::AlertTriggerRules::PerformanceAuditExceededThreshold

  MONITORABLE_FIELDS = [
    { field: 'bytes', name: 'Tag\'s JS File Size (bytes)' },
    { field: 'dom_complete_delta', name: 'Added DOM Complete Time (ms)' },
    { field: 'dom_content_loaded_delta', name: 'Added DOM Content Loaded Time (ms)' },
    { field: 'dom_interactive_delta', name: 'Added DOM Interactive Time (ms)' },
    # { field: 'entire_main_thread_execution_ms_delta', name: 'entire_main_thread_execution_ms_delta' },
    # { field: 'entire_main_thread_blocking_executions_ms_delta', name: 'entire_main_thread_blocking_executions_ms_delta' },
    { field: 'first_contentful_paint_delta', name: 'Added First Contentful Paint Time (ms)' },
    { field: 'layout_duration_delta', name: 'Added Layout Duration Time (ms)' },
    { field: 'main_thread_blocking_execution_tag_responsible_for_delta', name: 'Tag\'s Main Thread Blocking Time (ms)' },
    { field: 'main_thread_execution_tag_responsible_for_delta', name: 'Tag\'s Main Thread Execution (ms)' },
    { field: 'ms_until_first_visual_change_delta', name: 'Added Time Until First Visual Change (ms)' },
    # { field: 'perceptual_speed_index_delta', name: 'Perceptual Speed Index' },
    { field: 'script_duration_delta', name: 'Added Script Duration Time (ms)' },
    { field: 'speed_index_delta', name: 'Added Speed Index (ms)' },
    { field: 'task_duration_delta', name: 'Added Task Duration Time (ms)' },
    { field: 'tagsafe_score', name: 'Tagsafe Score' },
  ]

  def trigger_rules_description
    "Alert will trigger whenever a tag's #{trigger_rules.human_exceeded_metric} is #{trigger_rules.human_operator} #{trigger_rules.human_exceeded_metric_value}"
  end

  def triggered_alert_description(triggered_alert)
    "Your #{triggered_alert.tag.try_friendly_name} now has a #{trigger_rules.human_exceeded_metric(capitalize: true)} of #{triggered_alert.initiating_record.preferred_delta_performance_audit.send(trigger_rules.exceeded_metric)}, exceeding your threshold of #{trigger_rules.human_exceeded_metric_value}."
  end
end