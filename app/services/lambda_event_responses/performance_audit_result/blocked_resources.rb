module LambdaEventResponses
  class PerformanceAuditResult
    class BlockedResources
      def initialize(array_of_blocked_resources)
        @array_of_blocked_resources = array_of_blocked_resources
      end

      def formatted_and_filtered(performance_audit_id)
        @formatted_and_filtered ||= filtered.map{ |attrs| attrs.merge!(performance_audit_id: performance_audit_id) }
      end

      def filtered
        @filtered ||= @array_of_blocked_resources.select do |resource| 
          resource['url'].present? && !resource['url'].starts_with?('data:image/')
        end
      end
    end
  end
end