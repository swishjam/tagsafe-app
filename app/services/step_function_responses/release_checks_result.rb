module StepFunctionResponses
  class ReleaseChecksResult
    def initialize(lambda_response)
      @lambda_response = lambda_response
    end

    def process_results!
      create_release_check_batch
      if is_batch_of_uptime_checks_resulting_in_new_tag_versions?
        release_check_results.each do |release_check_result|
          release_check = ReleaseCheck.create!(release_check_result.formatted_for_create)
          capture_new_tag_version(release_check, release_check_result)
        end
      elsif release_check_results.any?
        ReleaseCheck.insert_all!(release_check_results_formatted_for_insert)
      end
      release_check_batch.touch(:processing_completed_at)
    end

    private

    def capture_new_tag_version(release_check, release_check_result)
      TagManager::TagVersionCapturer.new(
        tag: release_check_result.tag, 
        content: release_check_result.new_content,
        release_check: release_check,
        hashed_content: release_check_result.new_hashed_content,
        bytes: release_check_result.new_bytesize
      ).capture_new_tag_version!
      TagsafeAws::S3.delete_object_by_s3_url(release_check_result.new_tag_version_s3_url)
    end

    def release_check_results_formatted_for_insert
      release_check_results.map(&:formatted_for_create)
    end

    def release_check_results
      @release_check_results ||= @lambda_response['release_check_results'].map{ |result_hash| ReleaseCheckResult.new(result_hash, release_check_batch.id) }
    end

    def is_batch_of_uptime_checks_resulting_in_new_tag_versions?
      @lambda_response['is_for_new_tag_versions']
    end

    def release_check_batch
      @release_check_batch_result ||= ReleaseCheckBatchResult.new(@lambda_response).create_or_return_existing
    end
    alias create_release_check_batch release_check_batch

    def batch_uid
      @lambda_response['batch_uid']
    end

    def self.has_executed_step_function?
      false
    end
  end
end