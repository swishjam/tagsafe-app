class TagPreference < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :tag

  column_update_listener :should_run_audit
  after_update :check_to_run_audit
  # after_should_run_audit_updated_to true, -> { AfterTagShouldRunAuditActivationJob.perform_later(tag) }

  def check_to_run_audit
    if column_changed_to('monitor_changes', true)
      AfterTagShouldRunAuditActivationJob.perform_later(tag)
    end
  end
end