FactoryBot.define do
  factory :tag_preference do
    page_url_to_perform_audit_on { 'https://www.example.com' }
    is_third_party_tag { true }
    is_allowed_third_party_tag { false }
    monitor_changes { false }
    should_run_audit { false }
    should_log_tag_checks { true }
    consider_query_param_changes_new_tag { false }
    association :tag
  end
end