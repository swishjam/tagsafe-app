module Schedule
  class CleanOutOfRetentionDataJob < ApplicationJob
    def perform
      start_time = Time.now
      scripts_with_script_checks = Script.should_log_script_checks
      Rails.logger.info "Beginning CleanOutOfRetentionDataJob with #{scripts_with_script_checks.count} scripts."
      scripts_with_script_checks.each{ |script| DataRetention::ScriptChecks.new(script).purge! }
      Rails.logger.info "Completed CleanOutOfRetentionDataJob with #{scripts_with_script_checks.count} scripts in #{Time.now-start_time}."
    end
  end
end