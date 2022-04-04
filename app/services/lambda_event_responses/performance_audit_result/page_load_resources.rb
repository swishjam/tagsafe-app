module LambdaEventResponses
  class PerformanceAuditResult
    class PageLoadResources
      def initialize(array_of_page_load_resources = [])
        @array_of_page_load_resources = array_of_page_load_resources
      end

      def formatted(performance_audit_id = nil)
        @array_of_page_load_resources.map do |resource| 
          {
            performance_audit_id: performance_audit_id,
            name: resource['name'],
            entry_type: resource['entryType'],
            fetch_start: resource['fetchStart'],
            response_end: resource['responseEnd'],
            duration: resource['duration'],
            initiator_type: resource['initiatorType']
          }
        end
      end
    end
  end
end