FactoryBot.define do
  factory :audit, aliases: [:completed_audit] do
    association :script_change
    association :script_subscriber
    association :execution_reason
    primary { true }
    lighthouse_audit_enqueued_at { DateTime.yesterday }
    lighthouse_audit_completed_at { DateTime.now }
    lighthouse_audit_iterations { 3 }
    test_suite_enqueued_at { DateTime.yesterday }
    test_suite_completed_at { DateTime.now }
  end

  factory :audit_with_pending_lighthouse, parent: :audit do
    lighthouse_audit_completed_at { nil }
  end

  factory :audit_with_failed_lighthouse, parent: :audit do
    lighthouse_error_message { 'Oops! An error occurred!' }
  end
end

