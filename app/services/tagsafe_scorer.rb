class TagsafeScorer
  def initialize(
    performance_audit_calculator:, 
    dom_complete_delta:, 
    dom_content_loaded_delta:, 
    dom_interactive_delta:, 
    first_contentful_paint_delta:, 
    speed_index_delta:,
    perceptual_speed_index_delta:,
    main_thread_execution_tag_responsible_for_delta:,
    main_thread_blocking_execution_tag_responsible_for_delta:, # not yet available in PerformanceAuditCalculator
    entire_main_thread_execution_ms_delta:, # not yet available in PerformanceAuditCalculator
    entire_main_thread_blocking_executions_ms_delta:, # not yet available in PerformanceAuditCalculator
    ms_until_first_visual_change_delta:,
    ms_until_last_visual_change_delta:,
    task_duration_delta:, 
    script_duration_delta:, 
    layout_duration_delta:, 
    byte_size:
  )
    @performance_audit_calculator = performance_audit_calculator
    @dom_complete = dom_complete_delta
    @dom_content_loaded = dom_content_loaded_delta
    @dom_interactive = dom_interactive_delta
    @first_contentful_paint = first_contentful_paint_delta
    @speed_index = speed_index_delta
    @perceptual_speed_index = perceptual_speed_index_delta
    @main_thread_execution_tag_responsible_for = main_thread_execution_tag_responsible_for_delta
    @ms_until_first_visual_change = ms_until_first_visual_change_delta || 0
    @ms_until_last_visual_change = ms_until_last_visual_change_delta || 0
    @task_duration = task_duration_delta
    @script_duration = script_duration_delta
    @layout_duration = layout_duration_delta
    @byte_size = byte_size
    ensure_no_nil_metrics!
  end

  def score!
    100 - 
      performance_metric_deduction(:dom_complete) - 
      performance_metric_deduction(:dom_content_loaded) - 
      performance_metric_deduction(:dom_interactive) - 
      performance_metric_deduction(:first_contentful_paint) - 
      performance_metric_deduction(:task_duration) -
      performance_metric_deduction(:script_duration) -
      performance_metric_deduction(:layout_duration) -
      performance_metric_deduction(:byte_size) -
      performance_metric_deduction(:speed_index, return_zero_if_metric_is_nil: true) - 
      performance_metric_deduction(:perceptual_speed_index, return_zero_if_metric_is_nil: true) - 
      performance_metric_deduction(:main_thread_execution_tag_responsible_for) -
      performance_metric_deduction(:ms_until_first_visual_change, return_zero_if_metric_is_nil: true) - 
      performance_metric_deduction(:ms_until_last_visual_change, return_zero_if_metric_is_nil: true) 
  end

  # Return 0 in scenarios where some metrics can be nil for individual performance audits due to faulty Geppetto performance audits
  # AverageDeltaPerformanceAudit should filter these out (but may be less accurate do to less data)
  def performance_metric_deduction(metric_key, return_zero_if_metric_is_nil: false)
    return 0.0 if decrement_amount_for_metric(metric_key).zero? || weight_for_metric(metric_key).zero? || (instance_variable_get(:"@#{metric_key}").nil? && return_zero_if_metric_is_nil)
    deduction = (instance_variable_get(:"@#{metric_key}")/decrement_amount_for_metric(metric_key)) * weight_for_metric(metric_key)
    deduction > weight_for_metric(metric_key)*100 ? weight_for_metric(metric_key)*100 : deduction
  rescue => e
    raise GenericTagSafeError, "Error calculating score deduction for #{metric_key}.\n Using Performance Audit Calculator: #{@performance_audit_calculator.to_json}.\nError: #{e.inspect}"
  end

  private

  def ensure_no_nil_metrics!
    %i[dom_complete dom_content_loaded dom_interactive first_contentful_paint task_duration script_duration layout_duration byte_size].each do |metric|
      raise StandardError, "Cannt calculate Tagsafe Score, #{metric} is nil" if instance_variable_get("@#{metric.to_s}").nil?
    end
  end

  def weight_for_metric(metric_key)
    @performance_audit_calculator[:"#{metric_key}_weight"]
  end

  def decrement_amount_for_metric(metric_key)
    @performance_audit_calculator[:"#{metric_key}_score_decrement_amount"]
  end
end