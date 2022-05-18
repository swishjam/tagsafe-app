FactoryBot.define do
  factory :initial_audit_execution, class: ExecutionReason do
    name { 'Initial Audit' }
  end

  factory :manual_execution, class: ExecutionReason do
    name { 'Manual Execution' }
  end

  factory :release_monitoring_activated, class: ExecutionReason do
    name { 'Activated Release Monitoring' }
  end

  factory :scheduled_execution, class: ExecutionReason do
    name { 'Scheduled Execution' }
  end

  factory :new_tag_version_execution, class: ExecutionReason do
    name { 'New Tag Version' }
  end
  
  factory :retry_execution, class: ExecutionReason do
    name { 'Retry' }
  end
end