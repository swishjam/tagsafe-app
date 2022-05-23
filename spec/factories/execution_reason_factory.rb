FactoryBot.define do
  factory :manual_execution, class: ExecutionReason do
    name { 'Manual' }
  end

  factory :release_monitoring_activated, class: ExecutionReason do
    name { 'Activated Release Monitoring' }
  end

  factory :scheduled_execution, class: ExecutionReason do
    name { 'Scheduled' }
  end

  factory :new_release_execution, class: ExecutionReason do
    name { 'New Release' }
  end
  
  factory :tagsafe_provided_execution, class: ExecutionReason do
    name { 'Tagsafe Provided' }
  end
end