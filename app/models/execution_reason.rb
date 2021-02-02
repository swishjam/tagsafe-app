class ExecutionReason < ApplicationRecord
  has_many :test_group_runs

  def self.REASON_TYPES
    ['Manual Execution', 'Scheduled Execution', 'Script Change', 'Test']
  end

  def self.BILLABLE
    [self.INITIAL_AUDIT, self.MANUAL, self.TAG_CHANGE, self.SCHEDULED, self.REACTIVATED_TAG]
  end

  def self.INITIAL_AUDIT
    @initial_audit ||= find_by!(name: 'Initial Audit')
  end

  def self.REACTIVATED_TAG
    @reactivated_tag ||= find_by!(name: 'Reactivated Tag')
  end

  def self.MANUAL
    @manual ||= find_by!(name: 'Manual Execution')
  end

  def self.SCHEDULED
    @scheduled ||= find_by!(name: 'Scheduled Execution')
  end

  def self.TAG_CHANGE
    @tag_change ||= find_by!(name: 'Tag Change')
  end

  def self.RETRY
    @retry ||= find_by!(name: 'Retry')
  end
end