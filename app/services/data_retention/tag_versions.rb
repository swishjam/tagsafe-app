module DataRetention
  class TagVersions < Base
    def initialize(tag_version)
      @tag_version = tag_version
      @purge_log_message = "Purging #{records_to_purge.count} tag_versions based on the retention count of #{retention_count} for #{@tag_version.tag.full_url}"
    end

    def records_to_purge
      @records ||= @tag_version.tag.tag_versions.most_recent_first.offset(retention_count)
    end

    def retention_count
      @retention_count ||= @tag_version.tag.domain.organization.tag_version_retention_count
    end
  end
end