module DataRetention
  class TagChecks < Base
    def initialize(tag)
      @tag = tag
      @purge_log_message = "Purging #{records_to_purge.count} tag_checks based on the retention count of #{retention_count} for #{@tag.full_url}."
    end

    def records_to_purge
      @records ||= @tag.tag_checks.most_recent_first.offset(retention_count)
    end

    def retention_count
      @retention_count ||= @tag.domain.organization.tag_check_retention_count
    end
  end
end
