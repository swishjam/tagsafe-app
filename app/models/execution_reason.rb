class ExecutionReason < ApplicationRecord
  def self.INITIAL_AUDIT
    @initial_audit ||= find_by!(name: 'Initial Audit')
  end

  def self.ACTIVATED_TAG
    @reactivated_tag ||= find_by!(name: 'Activated Tag')
  end

  def self.MANUAL
    @manual ||= find_by!(name: 'Manual Execution')
  end

  def self.SCHEDULED
    @scheduled ||= find_by!(name: 'Scheduled Execution')
  end

  def self.NEW_TAG_VERSION
    @tag_change ||= find_by!(name: 'New Tag Version')
  end

  def self.RETRY
    @retry ||= find_by!(name: 'Retry')
  end
end