class AfterScriptSubscriberActivationJob < ApplicationJob
   def perform(script_subscriber)
      evaluator = script_subscriber.script.evaluate_script_content
      # if the script changed, let the after_create callback in script_change.rb handle the audit
      unless evaluator.script_changed?
        script_subscriber.run_audit!(script_subscriber.script.most_recent_change, ExecutionReason.REACTIVATED_TAG)
      end
   end
end