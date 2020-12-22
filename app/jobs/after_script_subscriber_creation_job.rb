class AfterScriptSubscriberCreationJob < ApplicationJob
  def perform(script_subscriber, initial_scan = false)
    if ENV['RUN_BASELINE_AUDITS'] == 'true'
      script_subscriber.run_baseline_audit!
    else
      Resque.logger.info "RUN_BASELINE_AUDITS is not turned on, bypassing baseline audit."
    end
    NotificationModerator::NewTagNotifier.new(script_subscriber).notify! unless initial_scan
  end
end