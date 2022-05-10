module StepFunctionResponses
  class UptimeChecksResult
    class UptimeCheckBatchResult
      def initialize(uptime_checks_hash)
        @uptime_checks_hash = uptime_checks_hash
      end

      def create_uptime_check_batch!
        UptimeCheckBatch.create!(
          batch_uid: @uptime_checks_hash['batch_uid'],
          uptime_region: uptime_region,
          num_tags_checked: @uptime_checks_hash['total_num_tags_checked'],
          executed_at: @uptime_checks_hash['executed_at'].nil? ? @uptime_checks_hash['executed_at'] : Time.at(@uptime_checks_hash['executed_at'] / 1_000).to_datetime,
          ms_to_run_check: @uptime_checks_hash['ms_to_complete_all_checks']
        )
      end

      private

      def uptime_region
        @uptime_region ||= UptimeRegion.FOR_AWS_REGION(@uptime_checks_hash['aws_region'])
      end
    end
  end
end