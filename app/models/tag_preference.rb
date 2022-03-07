class TagPreference < ApplicationRecord
  acts_as_paranoid
  
  belongs_to :tag
  
  after_update :check_to_run_audit

  TAG_CHECK_INTERVALS = [
    { name: '1 minute', value: 1 },
    { name: '15 minutes', value: 15 },
    { name: '30 minutes', value: 30 },
    { name: '1 hour', value: 60 },
    { name: '3 hours', value: 180 },
    { name: '6 hours', value: 360 },
    { name: '12 hours', value: 720 },
    { name: '1 day', value: 1_440 },
  ].freeze

  def check_to_run_audit
    if column_changed_to('enabled', true)
      AfterTagShouldRunAuditActivationJob.perform_later(tag)
    end
  end
end