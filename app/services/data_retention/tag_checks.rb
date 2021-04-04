module DataRetention
  class TagChecks < Base
    def initialize(tag)
      @tag = tag
      @purge_log_message = "Purging #{records_to_purge.count} script_checks based on the retention count of #{@tag.tag_check_retention_count} for #{@tag.url}."
    end

    def records_to_purge
      @records ||= @tag.tag_checks.most_recent_first.offset(@tag.tag_check_retention_count)
    end
  end
end
