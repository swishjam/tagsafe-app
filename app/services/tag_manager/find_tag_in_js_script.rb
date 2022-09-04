module TagManager
  class FindTagInJsScript
    class ExecutionError < StandardError; end;

    def self.find!(js_script)
      raise ExecutionError, "Provided script is empty." if js_script.blank?
      result = TagsafeAws::Lambda.invoke_function(
        function_name: "script-tag-finder-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-find-tags",
        payload: { snippet: js_script },
        async: false
      )
      raise ExecutionError, "Provided script threw an error: #{result['errorMessage']}" if result.is_a?(Hash) && result['errorMessage']
      Rails.logger.warn "Found #{result.count} (#{result.join(', ')}) tag URLs when evaluting script #{js_script}, only returning the first one..." if result.count > 1
      Rails.logger.warn "Found 0 tag URLs when evaluting script #{js_script}" if result.count.zero?
      result[0]
    end
  end
end