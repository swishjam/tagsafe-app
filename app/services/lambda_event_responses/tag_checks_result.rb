module LambdaEventResponses
  class TagChecksResult
    def initialize(lambda_response)
      @lambda_response = lambda_response
    end

    def process_results!
      if is_batch_of_tag_checks_resulting_in_new_tag_versions?
        tag_check_results.each do |tag_check_result|
          tc = TagCheck.create!(tag_check_result.formatted_for_create)
          TagManager::TagVersionCapturer.new(
            tag: tag_check_result.tag, 
            content: tag_check_result.new_content,
            tag_check: tc,
            hashed_content: tag_check_result.new_hashed_content,
            bytes: tag_check_result.new_bytesize
          ).capture_new_tag_version!
          TagsafeAws::S3.delete_object_by_s3_url(tag_check_result.new_tag_version_s3_url)
        end
      else
        TagCheck.insert_all!(tag_check_results_formatted_for_insert)
      end
    end

    def tag_check_results_formatted_for_insert
      tag_check_results.map(&:formatted_for_create)
    end

    def tag_check_results
      @tag_check_results ||= @lambda_response['tag_check_results'].map{ |res| TagCheckResult.new(res, aws_region: @lambda_response['aws_region']) }
    end

    def is_batch_of_tag_checks_resulting_in_new_tag_versions?
      @lambda_response['is_for_new_tag_versions']
    end

    def self.has_executed_lambda_function?
      false
    end
  end
end