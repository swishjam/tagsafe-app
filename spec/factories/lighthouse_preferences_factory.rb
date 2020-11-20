FactoryBot.define do
  factory :lighthouse_preference do
    association :script_subscriber
    url_to_audit { 'https://www.test.com' }
    should_run_audit { false }
    num_test_iterations { 3 }
    should_capture_individual_audit_metrics { false }
    performance_impact_threshold { 0.1 }
  end
end