module Schedule
  module ScheduledAuditJobs
    class Base < ApplicationJob
      queue_as :scheduled_audit_queue
  
      def perform(opts = {})
        start = Time.new
        audit_count = 0
        tags_to_audit = Tag.send(interval_scope)
        Rails.logger.info "#{self.class.to_s} is enqueueing audits on #{tags_to_audit.count} tags..."
        tags_to_audit.each do |tag|
          audits = tag.perform_audit_on_all_urls_on_current_tag_version!(execution_reason: ExecutionReason.SCHEDULED)
          audit_count += audits.count
        end
        Rails.logger.info "#{self.class} enqueued #{audit_count} audits in #{Time.new - start} seconds."
      end

      private

      # turns Schedule::ScheduledAuditJobs::FiveMinuteScheduledAuditInterval class to :five_minute_scheduled_audit_intervals
      def interval_scope
        "#{self.class.to_s}s".split('::').last.split(/(?=[A-Z])/).map{ |word| word.downcase! }.join('_').to_sym
      end
    end
  end
end