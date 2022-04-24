module TagManager
  class CommitMessageParser
    REGEXP = /TS-m__(.*?)__TS-m/
    # TS-m__ commit message goes here __TS-m
    
    def initialize(js_content)
      @js_content = js_content
    end

    def try_to_get_commit_message
      match_results = @js_content.match(REGEXP)
      return if match_results.nil?
      match_results.captures[0]
    end
  end
end