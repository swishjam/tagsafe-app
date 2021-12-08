module Schedule
  class CleanOutOfRetentionDataJob < ApplicationJob
    def perform
      start_time = Time.now
      # tags_with_tag_checks = Tag.should_log_tag_checks
      all_tags = Tag.all
      Rails.logger.info "Beginning CleanOutOfRetentionDataJob with #{all_tags.count} tags."
      all_tags.each{ |tag| DataRetention::TagChecks.new(tag).purge! }
      Rails.logger.info "Completed CleanOutOfRetentionDataJob with #{all_tags.count} tags in #{Time.now - start_time} seconds."
    end
  end
end