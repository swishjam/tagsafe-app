class ScriptTestType < ApplicationRecord
  has_many :test_runs
  has_many :lighthouse_audit_results

  def self.CURRENT_TAG
    @current_tag || find_by(name: 'Current Tag')
  end

  def self.PREVIOUS_TAG
    @previous_tag ||= find_by(name: 'Previous Tag')
  end

  def self.WITHOUT_TAG
    @without_tag ||= find_by(name: 'Without Tag')
  end

  def self.DELTA
    @delta ||= find_by(name: 'Delta')
  end

  def self.AVERAGE
    @average ||= find_by(name: 'Average')
  end
end