module ChartHelper
  class ScriptSubscriberData
    def initialize(script_subscriber, chart_type, metric_keys)
      @script_subscriber = script_subscriber
      @chart_type = chart_type
      @metric_keys = metric_keys
      @chart_data = []
    end

    def get_metric_data!
      grouped_performance_audit_metrics.each do |dataset_tite, audit_metrics|
        metric_data = { name: dataset_tite, data: {} }
        audit_metrics.each do |metric|
          metric_data[:data][metric.performance_audit.audit.script_change.created_at] = metric.result
        end
        @chart_data << metric_data
      end
      @chart_data
    end

    private

    def grouped_performance_audit_metrics
      PerformanceAuditMetric.includes(performance_audit: [audit: [:script_change]])
                              .by_script_subscriber(@script_subscriber)
                              .by_audit_type(audit_types)
                              .primary_audits
                              .by_key(@metric_keys)
                              .group_by{ |metric| grouped_by_method(metric) }
    end

    def grouped_by_method(metric)
      [metric.title, friendly_audit_type_name(metric.performance_audit)].join(' ')
    end

    def friendly_audit_type_name(performance_audit)
      case performance_audit.type
      when 'DeltaPerformanceAudit'
        'Impact'
      when 'PerformanceAuditWithTag'
        'With Tag'
      when 'PerformanceAuditWithoutTag'
        'Without Tag'
      end
    end

    def audit_types
      @chart_type == 'impact' ? 'DeltaPerformanceAudit' : ['PerformanceAuditWithTag', 'PerformanceAuditWithoutTag']
    end
  end
end

#   if chart_type == 'impact'
    
#   else
#     PerformanceAuditMetric.includes(performance_audit: [audit: [:script_change]])
#                           .by_script_subscriber(@script_subscriber)
#                           .by_audit_type(['PerformanceAuditWithTag', 'PerformanceAuditWithoutTag'])
#                           .primary_audits
#                           .by_key(keys)
#                           .group_by{ |metric| 
#                             [metric.performance_audit.type, metric.title].join(' - ') 
#                           }.each do |metric_obj|
#       metric_data = { name: metric_obj[0], data: {} }
#       metric_obj[1].each do |metric|
#         metric_data[:data][metric.performance_audit.audit.script_change.created_at] = metric.result
#       end
#       chart_data << metric_data
#     end
#   end
# end