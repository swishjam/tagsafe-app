class OneMinuteScriptCheckerJob < ApplicationJob
  @queue = :script_checker_queue
  queue_as :script_checker_queue

  def perform
    start = Time.new
    Script.monitor_changes
            .one_minute_interval_checks
            .with_active_subscribers
            .still_on_site.each { |script| script.evaluate_script_content }
    Resque.logger.info "OneMinuteScriptCheckerJob Completed in #{Time.new - start} seconds."
  end
end