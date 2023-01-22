module TagManager
  class FindTagsInTagSnippet
    def self.find!(encoded_tag_snippet_content)
      TagsafeAws::Lambda.invoke_function(
        function_name: "find-tags-#{ENV['LAMBDA_ENVIRONMENT'] || Rails.env}-find-tags",
        async: false,
        payload: { encoded_tag_snippet_content: encoded_tag_snippet_content },
      )
    end
  end
end