module Schedule
  class CleanOutOfRetentionDataJob < ApplicationJob
    def perform
      start_time = Time.now
      tags_with_tag_checks = Tag.should_log_tag_checks
      Rails.logger.info "Beginning CleanOutOfRetentionDataJob with #{tags_with_tag_checks.count} tag."
      tags_with_tag_checks.each{ |script| DataRetention::TagChecks.new(script).purge! }
      Rails.logger.info "Completed CleanOutOfRetentionDataJob with #{tags_with_tag_checks.count} tags in #{Time.now-start_time}."
    end
  end
end