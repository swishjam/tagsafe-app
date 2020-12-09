FactoryBot.define do
  factory :performance_audit_preference do
    association :script_subscriber
    url_to_audit { 'https://www.test.com' }
    should_run_audit { false }
    num_test_iterations { 3 }
  end
end