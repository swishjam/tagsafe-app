class RunAuditForScriptSubscriberJob < ApplicationJob
  def perform(script_subscriber, script_change, execution_reason)
    script_subscriber.run_audit!(script_change, execution_reason)
  end
end