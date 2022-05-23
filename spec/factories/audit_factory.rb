FactoryBot.define do
  factory :audit, aliases: [:completed_audit] do
    association :tag_version
    association :tag
    association :execution_reason
    association :page_url
    include_performance_audit { true }
    include_functional_tests { true }
    include_page_load_resources { true }
    num_functional_tests_to_run { 0 }
    enqueued_suite_at { 20.minutes.ago }
    performance_audit_completed_at { 1.minute.ago }
  end

  factory :audit_with_failed_performance_audit, parent: :audit do
    performance_audit_error_message { 'Oops! An error occurred!' }
  end

  factory :pending_audit, parent: :audit do
    enqueued_suite_at { 5.minutes.ago }
    completed_at { nil }
  end
end

