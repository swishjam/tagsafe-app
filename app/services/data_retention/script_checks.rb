module DataRetention
  class ScriptChecks < Base
    def initialize(script)
      @script = script
      @purge_log_message = "Purging #{records_to_purge.count} script_checks based on the retention count of #{highest_retention_count} for #{@script.url}."
    end

    def records_to_purge
      @records ||= @script.script_checks.most_recent_first.offset(highest_retention_count)
    end

    def highest_retention_count
      @highest_retention_count ||= @script.script_subscribers.collect(&:script_check_retention_count).max
    end
  end
end
