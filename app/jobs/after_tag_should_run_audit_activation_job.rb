class AfterTagShouldRunAuditActivationJob < ApplicationJob
   def perform(tag)
      evaluator = tag.capture_changes_if_tag_changed
      # if the script changed, let the after_create callback in tag_version.rb handle the audit
      # if it did not change, run the audit now...?
      unless evaluator.tag_changed?
        tag.most_recent_version.run_audit!(ExecutionReason.REACTIVATED_TAG)
      end
   end
end