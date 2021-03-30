module DataRetention
  class ScriptChanges < Base
    def initialize(script_change)
      @script_change = script_change
      @purge_log_message = "Purging #{records_to_purge.count} script_changes based on the retention count of #{highest_retention_count} for #{@script_change.script.url}"
    end

    def records_to_purge
      @records ||= @script_change.script.script_changes.most_recent_first.offset(highest_retention_count)
    end

    def highest_retention_count
      @highest_retention_count ||= @script_change.script.script_subscribers.collect(&:script_change_retention_count).max
    end
  end
end