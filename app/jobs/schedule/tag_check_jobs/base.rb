module Schedule
  module TagCheckJobs
    class Base < ApplicationJob
      queue_as :tag_checker_queue
  
      def perform(opts = {})
        start = Time.new
        tag_check_count = 0
        new_tag_version_count = 0
        Tag.should_run_tag_checks.domain_has_active_subscription_plan.send(interval_scope).each do |tag|
          tag_check_count += 1
          begin
            evaluator = tag.run_tag_check!
            new_tag_version_count += 1 if evaluator.detected_new_tag_version?
          rescue => e
            Rails.logger.error "UNABLE TO EVALUATE TAG CHECK FOR TAG #{tag.uid}: #{e.message}"
            Sentry.capture_exception(e)
          end
        end
        Resque.logger.info "#{self.class} evaluated #{tag_check_count} tags in #{Time.new - start} seconds and captured #{new_tag_version_count} new TagVersions."
      end

      private

      # turns Schedule::TagCheckJobs::OneMinuteInterval class to :one_minute_interval_checks
      def interval_scope
        "#{self.class.to_s}Checks".split('::').last.split(/(?=[A-Z])/).map{ |word| word.downcase! }.join('_').to_sym
      end
    end
  end
end