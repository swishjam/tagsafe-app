class UpdateDomainsScriptsJob < ApplicationJob
  @queue = :default
  
  def perform(domain, script_urls)
    script_urls.each do |url|
      existing_script = Script.find_by(url: url)
      if existing_script
        unless domain.subscribed_to_script? existing_script
          script_subscriber = domain.subscribe!(existing_script)
          script_subscriber.run_audit!(script_subscriber.script.most_recent_change, ExecutionReason.FIRST_AUDIT)
        end
      else
        # first script subscriber
        script = Script.create(url: url, should_log_script_checks: false)
        script_subscriber = domain.subscribe!(script)
        evaluator = script.evaluate_script_content
        # if the script changed, let the script change hook run the audit
        # unless evaluator.script_changed?
        #   script_subscriber.run_audit!(script_subscriber.script.most_recent_change, ExecutionReason.FIRST_AUDIT)
        # end
      end
    end
  end
end