module TagManager
  class FindTagInJsScript
    class << self
      def find!(js_script)
        tags = TagsafeAws::Lambda.invoke_function(
          function_name: "script-tag-finder-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-find-tags",
          payload: { snippet: js_script },
          async: false
        )
      end
    end
  end
end