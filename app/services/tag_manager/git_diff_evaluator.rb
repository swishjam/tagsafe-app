module TagManager
  class GitDiffEvaluator
    def initalize(new_content, previous_content)
      @new_content = new_content
      @previous_content = previous_content
    end

    def number_of_additions
    end

    def number_of_deletions
    end

    private

    def diffy
      @diffy ||= Diffy::Diff.new(
        @previous_content.force_encoding('UTF-8'), 
        @new_content.force_encoding('UTF-8'), 
        format: :html
      ).to_s(:html)
    end

    def parse_diff_for_additions_and_deletions
      dom = Nokogiri::HTML(diffy)
    
      additions = dom.css("ins")
      deletions = dom.css("del")
    end
  end
end