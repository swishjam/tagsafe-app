class ScriptCheckerJob < ApplicationJob
  @queue = :script_checker_queue
  queue_as :script_checker_queue

  def perform
    MonitoredScript.all.each { |script| script.evaluate_script_details }
  end
end