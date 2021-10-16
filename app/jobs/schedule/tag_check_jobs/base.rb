module Schedule
  module TagCheckJobs
    class Base < ApplicationJob
      queue_as :tag_checker_queue
  
      def perform(opts = {})
        start = Time.new
        count = 0
        Tag.send(interval_scope).should_run_tag_checks.each do |tag|
          count += 1
          tag.capture_changes_if_tag_changed
        end
        Resque.logger.info "#{self.class} evaluated #{count} tags in #{Time.new - start} seconds."
      end

      private

      # turns Schedule::TagCheckJobs::OneMinuteInterval class to :one_minute_interval_checks
      def interval_scope
        "#{self.class.to_s}Checks".split('::').last.split(/(?=[A-Z])/).map{ |word| word.downcase! }.join('_').to_sym
      end
    end
  end
end