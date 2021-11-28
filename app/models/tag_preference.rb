class TagPreference < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :tag
  
  after_update :check_to_run_audit

  def check_to_run_audit
    if column_changed_to('enabled', true)
      AfterTagShouldRunAuditActivationJob.perform_later(tag)
    end
  end
end