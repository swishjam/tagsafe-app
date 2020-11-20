FactoryBot.define do
  factory :manual_execution, class: 'ExecutionReason' do
    name { 'Manual Execution' }
  end

  factory :reactivated_script_execution, class: 'ExecutionReason' do
    name { 'Reactivated Script' }
  end

  factory :scheduled_execution, class: 'ExecutionReason' do
    name { 'Scheduled Execution' }
  end

  factory :script_change_execution, class: 'ExecutionReason' do
    name { 'Script Change' }
  end

  factory :initial_test_execution, class: 'ExecutionReason' do
    name { 'Initial Test' }
  end

  factory :test_execution, class: 'ExecutionReason' do
    name { 'Test' }
  end
end