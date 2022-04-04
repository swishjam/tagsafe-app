class ExecutionReason < ApplicationRecord
  scope :free, -> { where(name: ['Manual', 'Tagsafe Provided']) }
  scope :billable, -> { where(name: ['Activated Tag', 'Scheduled', 'New Release']) }
  scope :automated, -> { billable }

  def self.INITIAL_AUDIT
    @initial_audit ||= find_by!(name: 'Initial Audit')
  end

  def self.TAGSAFE_PROVIDED
    @tagsafe_provided ||= find_by!(name: 'Tagsafe Provided')
  end

  def self.ACTIVATED_TAG
    @reactivated_tag ||= find_by!(name: 'Activated Tag')
  end

  def self.MANUAL
    @manual ||= find_by!(name: 'Manual')
  end

  def self.SCHEDULED
    @scheduled ||= find_by!(name: 'Scheduled')
  end

  def self.NEW_RELEASE
    @tag_change ||= find_by!(name: 'New Release')
  end
end