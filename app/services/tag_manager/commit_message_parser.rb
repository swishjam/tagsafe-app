module TagManager
  class CommitMessageParser
    REGEXP = /(?<=TS-m__)([^(__TS)]+)/
    # TS-m__ commit message goes here __TS-m
    
    def initialize(js_content)
      @js_content = js_content
    end

    def try_to_get_commit_message
      (@js_content.match(REGEXP) || [])[0]
    end
  end
end