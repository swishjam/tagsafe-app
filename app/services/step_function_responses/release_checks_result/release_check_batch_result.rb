module StepFunctionResponses
  class ReleaseChecksResult
    class ReleaseCheckBatchResult
      def initialize(release_checks_hash)
        @release_checks_hash = release_checks_hash
      end

      def create_or_return_existing
        ReleaseCheckBatch.find_by(batch_uid: @release_checks_hash['batch_uid']) || create_release_check_batch!
      end

      private

      def create_release_check_batch!
        ReleaseCheckBatch.create!(
          batch_uid: @release_checks_hash['batch_uid'],
          minute_interval: @release_checks_hash['interval'],
          num_tags_with_new_versions: @release_checks_hash['num_tags_with_new_versions'],
          num_tags_without_new_versions: @release_checks_hash['num_tags_without_new_versions'],
          executed_at: @release_checks_hash['executed_at'].nil? ? nil : Time.at(@release_checks_hash['executed_at'] / 1_000).to_datetime,
          ms_to_run_check: @release_checks_hash['ms_to_complete_all_checks']
        )
      end
    end
  end
end