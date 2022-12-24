module TagManager
  class CommitMessageParser
    REGEXP = /TS-m__(.*?)__TS-m/
    # TS-m__ commit message goes here __TS-m
  
    def self.try_to_get_commit_message(js_content)
      match_results = js_content.match(REGEXP)
      return if match_results.nil?
      match_results.captures[0]
    end
  end
end