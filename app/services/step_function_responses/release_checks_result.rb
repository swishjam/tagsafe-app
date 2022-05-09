module StepFunctionResponses
  class ReleaseChecksResult
    def initialize(lambda_response)
      @lambda_response = lambda_response
    end

    def process_results!
      if is_batch_of_uptime_checks_resulting_in_new_tag_versions?
        release_check_results.each do |release_check_result|
          rc = ReleaseCheck.create!(release_check_result.formatted_for_create)
          TagManager::TagVersionCapturer.new(
            tag: release_check_result.tag, 
            content: release_check_result.new_content,
            release_check: rc,
            hashed_content: release_check_result.new_hashed_content,
            bytes: release_check_result.new_bytesize
          ).capture_new_tag_version!
          TagsafeAws::S3.delete_object_by_s3_url(release_check_result.new_tag_version_s3_url)
        end
      else
        ReleaseCheck.insert_all!(release_check_results_formatted_for_insert)
      end
    end

    def release_check_results_formatted_for_insert
      release_check_results.map(&:formatted_for_create)
    end

    def release_check_results
      @release_check_results ||= @lambda_response['release_check_results'].map{ |res| ReleaseCheckResult.new(res) }
    end

    def is_batch_of_uptime_checks_resulting_in_new_tag_versions?
      @lambda_response['is_for_new_tag_versions']
    end

    def self.has_executed_step_function?
      false
    end
  end
end