module ChartHelper
  class ScriptSubscriberData
    def initialize(script_subscriber)
      @script_subscriber = script_subscriber
    end

    def get_metric_data_by_keys!(keys)
      chart_data = []
      if keys.include?('psi')
        chart_data.concat(get_psi_data!)
      end
      keys.delete('psi')
      LighthouseAuditMetric.includes(lighthouse_audit: [audit: [:script_change]])
                            .by_script_subscriber(@script_subscriber)
                            .by_lighthouse_audit_type('DeltaLighthouseAudit')
                            .primary_audits
                            .by_key(keys)
                            .group_by(&:title).each do |metric_obj|
        metric_data = { name: metric_obj[0], data: {} }
        metric_obj[1].each do |metric|
          metric_data[:data][metric.lighthouse_audit.audit.script_change.created_at] = metric.result
        end
        chart_data << metric_data
      end
      chart_data
    end

    def get_psi_data!
      psi_data = { name: 'Performance Score Impact', data: {} }
      @script_subscriber.lighthouse_audits
                          .includes(audit: [:script_change])
                          .by_lighthouse_audit_type('DeltaLighthouseAudit')
                          .primary_audits.each do |lighthouse_audit|
        psi_data[:data][lighthouse_audit.audit.script_change.created_at] = lighthouse_audit.formatted_performance_score
      end
      [psi_data]
    end
  end
end