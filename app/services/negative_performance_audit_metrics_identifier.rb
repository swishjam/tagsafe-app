class NegativePerformanceAuditMetricsIdentifier
  METRIC_SLUG_TO_FRIENDLY_NAME_DICTIONARY = {
    dom_complete: 'DOM Complete',
    dom_content_loaded: 'DOM Content Loaded',
    dom_interactive: 'DOM Interactive',
    first_contentful_paint: 'First Contentful Paint',
    script_duration: 'Script Duration',
    task_duration: 'Task Duration'
  }.freeze

  def initialize(
    delta_performance_audit_to_analyze, 
    metrics_to_analyze: %i[dom_complete dom_content_loaded dom_interactive first_contentful_paint script_duration task_duration],
    percent_responsible_to_be_considered_negative: 30
  )
    @delta_performance_audit_to_analyze = delta_performance_audit_to_analyze
    @metrics_to_analyze = metrics_to_analyze
    @percent_responsible_to_be_considered_negative = percent_responsible_to_be_considered_negative

    @most_negative_performance_metric = nil
    @negative_performance_metrics = []
  end

  def most_negative_performance_metric
    analyze_audit!
    @most_negative_performance_metric
  end

  def negative_performance_metrics
    analyze_audit!
    @negative_performance_metrics
  end

  private

  def analyze_audit!
    return if @analyzed
    negative_performance_metric_struct = Struct.new(:metric_slug, :friendly_metric_name, :percent_responsible)
    @metrics_to_analyze.each do |metric|
      percent_responsible = @delta_performance_audit_to_analyze.send(:"#{metric}_percentage")
      if percent_responsible >= @percent_responsible_to_be_considered_negative
        @negative_performance_metrics << negative_performance_metric_struct.new(metric, METRIC_SLUG_TO_FRIENDLY_NAME_DICTIONARY[metric], percent_responsible)
      end
      if percent_responsible > (@most_negative_performance_metric&.percent_responsible || 0)
        @most_negative_performance_metric = negative_performance_metric_struct.new(metric, METRIC_SLUG_TO_FRIENDLY_NAME_DICTIONARY[metric], percent_responsible)
      end
    end
  end

end