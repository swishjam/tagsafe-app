module LambdaEventResponses
  class PerformanceAuditResult
    class BlockedResources
      def initialize(array_of_blocked_resources)
        @array_of_blocked_resources = array_of_blocked_resources
      end

      def filtered
        @filtered ||= @array_of_blocked_resources.select do |resource| 
          resource['url'].present? && !resource['url'].starts_with?('data:image/')
        end
      end
    end
  end
end