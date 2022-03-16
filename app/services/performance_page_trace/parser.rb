module PerformancePageTrace
  class Parser
    def initialize(performance_audit)
      @performance_audit = performance_audit
    end

    def get_filmstrip_screenshots
      @filmstrip_screenshots ||= all_events.where(name: 'Screenshot')
    end

    def get_navigation_timing_events
      @navigation_timing_events ||= all_events.where(type: PerformancePageTrace::EventTypes.MARK)
    end

    def get_events_related_to_audited_tag
      @events_related_to_audited_tag ||= all_events.where(resource_url: @performance_audit.audit.tag_version.js_file_url)
    end

    private

    def all_events
      @all_events ||= EventCollection.new(trace_json['traceEvents'])
    end

    def trace_json
      raise PerformanceAuditError::NoPageTraceError if @performance_audit.page_trace_s3_url.blank?
      @trace_json ||= JSON.parse TagsafeAws::S3.get_object_by_s3_url(@performance_audit.page_trace_s3_url).body.read
    end
  end
end