class ExecutionReason < ApplicationRecord
  has_many :test_group_runs
  has_many :lighthouse_audits

  def self.REASON_TYPES
    ['Manual Execution', 'Scheduled Execution', 'Script Change', 'Test']
  end

  def self.FIRST_AUDIT
    @first_audit ||= find_by(name: 'First Audit')
  end

  def self.REACTIVATED_SCRIPT
    @reactivated_script ||= find_by(name: 'Reactivated Script')
  end

  def self.MANUAL
    @manual ||= find_by(name: 'Manual Execution')
  end

  def self.SCHEDULED
    @scheduled ||= find_by(name: 'Scheduled Execution')
  end

  def self.SCRIPT_CHANGE
    @script_change ||= find_by(name: 'Script Change')
  end

  def self.INITIAL_TEST
    @initial_test ||= find_by(name: 'Initial Test')
  end

  def self.TEST
    @test ||= find_by(name: 'Test')
  end
end