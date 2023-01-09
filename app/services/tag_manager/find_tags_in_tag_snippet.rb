module TagManager
  class FindTagsInTagSnippet
    def self.find!(tag_snippet_js_content)
      TagsafeAws::Lambda.invoke_function(
        function_name: "find-tags-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-find-tags",
        payload: { tag_snippet_script: tag_snippet_js_content },
        async: false
      )
    end
  end
end