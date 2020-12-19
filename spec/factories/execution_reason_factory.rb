FactoryBot.define do
  factory :initial_audit_execution, class: 'ExecutionReason' do
    name { 'Initial Audit' }
  end

  factory :manual_execution, class: 'ExecutionReason' do
    name { 'Manual Execution' }
  end

  factory :reactivated_tag_execution, class: 'ExecutionReason' do
    name { 'Reactivated Tag' }
  end

  factory :scheduled_execution, class: 'ExecutionReason' do
    name { 'Scheduled Execution' }
  end

  factory :tag_change_execution, class: 'ExecutionReason' do
    name { 'Tag Change' }
  end
  
  factory :retry_execution, class: 'ExecutionReason' do
    name { 'Retry' }
  end
end