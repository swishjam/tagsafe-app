class ExecutionReason < ApplicationRecord
  scope :automated, -> { where(name: ['Activated Release Monitoring', 'Scheduled', 'New Release']) }

  TYPES_OF_EXECUTION_REASONS = [
    { method: :manual, name: 'Manual' },
    { method: :tagsafe_provided, name: 'Tagsafe Provided' },
    { method: :release_monitoring_activated, name: 'Activated Release Monitoring' },
    { method: :scheduled, name: 'Scheduled' },
    { method: :new_release, name: 'New Release' }
  ]
  
  TYPES_OF_EXECUTION_REASONS.each do |type_of_execution_reason|
    define_method(:"#{type_of_execution_reason[:method]}?") { name == type_of_execution_reason[:name] }
  end

  class << self
    TYPES_OF_EXECUTION_REASONS.each do |type_of_execution_reason|
      define_method(:"#{type_of_execution_reason[:method].upcase}") do 
        instance_variable_get(:"@#{type_of_execution_reason[:method].upcase}") || 
          instance_variable_set(:"@#{type_of_execution_reason[:method].upcase}", find_by!(name: type_of_execution_reason[:name]) )
      end
    end
  end

  def automated?
    release_monitoring_activated? || scheduled? || new_release?
  end
end