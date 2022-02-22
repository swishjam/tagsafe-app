module Schedule
  module TagCheckJobs
    class Base < ApplicationJob
      queue_as :tag_checker_queue
  
      def perform(opts = {})
        start = Time.new
        tag_check_count = 0
        new_tag_version_count = 0
        Tag.send(interval_scope).should_run_tag_checks.each do |tag|
          tag_check_count += 1
          evaluator = tag.run_tag_check!
          new_tag_version_count += 1 if evaluator.tag_released_new_tag_version?
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