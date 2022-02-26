class TagsafeScorer
  def initialize(
    performance_audit_calculator:, 
    dom_complete_delta:, 
    dom_content_loaded_delta:, 
    dom_interactive_delta:, 
    first_contentful_paint_delta:, 
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
      performance_metric_deduction(:byte_size)
  end

  def performance_metric_deduction(metric_key)
    deduction = (instance_variable_get("@#{metric_key.to_s}")/decrement_amount_for_key(metric_key)) * weight_for_metric_key(metric_key)
    deduction > weight_for_metric_key(metric_key)*100 ? weight_for_metric_key(metric_key)*100 : deduction
  rescue => e
    raise GenericTagSafeError, "Error calculating score deduction for #{metric_key}.\n Using Performance Audit Calculator: #{@performance_audit_calculator.to_json}.\nError: #{e.inspect}"
  end

  private

  def ensure_no_nil_metrics!
    %i[dom_complete dom_content_loaded dom_interactive first_contentful_paint task_duration script_duration layout_duration byte_size].each do |metric|
      raise StandardError, "Cannt calculate Tagsafe Score, #{metric} is nil" if instance_variable_get("@#{metric.to_s}").nil?
    end
  end

  def weight_for_metric_key(metric_key)
    @performance_audit_calculator["#{metric_key}_weight".to_sym]
  end

  def decrement_amount_for_key(metric_key)
    @performance_audit_calculator["#{metric_key}_score_decrement_amount".to_sym]
  end
end