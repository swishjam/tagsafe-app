class AfterScriptSubscriberCreationJob < ApplicationJob
  def perform(script_subscriber, first_scan = false)
    if ENV['RUN_BASELINE_AUDITS'] == 'true'
      script_subscriber.run_baseline_audit!
    else
      Resque.logger.info "RUN_BASELINE_AUDITS is not turned on, bypassing baseline audit."
    end
    unless first_scan
      # TODO: allow for option to receive new tag emails!
      script_subscriber.domain.organization.users.each do |user|
        TagSafeMailer.send_new_tag_detected_email(user, script_subscriber)
      end
    end
  end
end