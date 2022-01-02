class AfterTagShouldRunAuditActivationJob < ApplicationJob
   def perform(tag)
      evaluator = tag.run_tag_check!
      # if the script changed, let the after_create callback in tag_version.rb handle the audit
      # if it did not change, run the audit now...?
      unless evaluator.tag_changed?
         tag.current_version.perform_audit_later_on_all_urls(ExecutionReason.ACTIVATED_TAG)
      end
   end
end