FactoryBot.define do
  factory :audit, aliases: [:completed_audit] do
    association :script_change
    association :script_subscriber
    association :execution_reason
    primary { true }
    performance_audit_enqueued_at { DateTime.yesterday }
    performance_audit_completed_at { DateTime.now }
  end

  factory :audit_with_pending_performance_audit, parent: :audit do
    performance_audit_completed_at { nil }
  end

  factory :audit_with_failed_performance_audit, parent: :audit do
    performance_audit_error_message { 'Oops! An error occurred!' }
  end
end

