module TagManager
  class FindTagsInTagSnippet
    def self.find!(executable_javascript, script_tags_attributes)
      TagsafeAws::Lambda.invoke_function(
        function_name: "find-tags-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-find-tags",
        async: false,
        payload: {
          script_tags_attributes: script_tags_attributes,
          tag_snippet_script: executable_javascript,
        },
      )
    end
  end
end