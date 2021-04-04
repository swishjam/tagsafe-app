module Schedule
  class OneMinuteTagCheckerJob < ApplicationJob
    @queue = :script_checker_queue
    queue_as :script_checker_queue

    def perform
      start = Time.new
      count = 0
      Tag.one_minute_interval_checks.should_run_tag_checks.each do |tag| 
              count += 1
              tag.capture_tag_content
      end
      Resque.logger.info "OneMinuteTagCheckerJob evaluated #{count} tags in #{Time.new - start} seconds."
    end
  end
end