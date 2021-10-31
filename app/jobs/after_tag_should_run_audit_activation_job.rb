class AfterTagShouldRunAuditActivationJob < ApplicationJob
   def perform(tag)
      evaluator = tag.capture_changes_if_tag_changed
      # if the script changed, let the after_create callback in tag_version.rb handle the audit
      # if it did not change, run the audit now...?
      unless evaluator.tag_changed?
         tag.perform_audit_now_on_all_urls(ExecutionReason.ACTIVATED_TAG)
      end
   end
end