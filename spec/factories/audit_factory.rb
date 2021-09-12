FactoryBot.define do
  factory :audit, aliases: [:completed_audit] do
    association :tag_version
    association :tag
    association :execution_reason
    primary { true }
    performance_audit_iterations { 5 }
    enqueued_at { DateTime.yesterday }
    completed_at { DateTime.now }
  end

  factory :audit_with_failed_performance_audit, parent: :audit do
    performance_audit_error_message { 'Oops! An error occurred!' }
  end

  factory :pending_audit, parent: :audit do
    enqueued_at { 5.minutes.ago }
    completed_at { nil }
    primary { false }
  end
end

