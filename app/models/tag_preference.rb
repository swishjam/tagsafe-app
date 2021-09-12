class TagPreference < ApplicationRecord
  belongs_to :tag

  column_update_listener :should_run_audit
  after_update :check_to_run_audit
  # after_should_run_audit_updated_to true, -> { AfterTagShouldRunAuditActivationJob.perform_later(tag) }

  # validates :page_url_to_perform_audit_on, presence: true

  def check_to_run_audit
    if column_changed_to('should_run_audit', true)
      AfterTagShouldRunAuditActivationJob.perform_later(tag)
    end
  end
end