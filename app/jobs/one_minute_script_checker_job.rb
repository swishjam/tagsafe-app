class OneMinuteScriptCheckerJob < ApplicationJob
  @queue = :script_checker_queue
  queue_as :script_checker_queue

  def perform
    start = Time.new
    count = 0
    Script.monitor_changes
            .one_minute_interval_checks
            .with_active_subscribers
            .still_on_site.each do |script| 
              count += 1
              script.evaluate_script_content
    end
    Resque.logger.info "OneMinuteScriptCheckerJob evaluated #{count} tags in #{Time.new - start} seconds."
  end
end