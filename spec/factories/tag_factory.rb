FactoryBot.define do
  factory :tag do
    full_url { 'https://cdn.test.com/js' }
    url_domain { 'cdn.test.com' }
    url_path { '/js' }
    # url_query_param { nil }
    is_third_party_tag { true }
    is_allowed_third_party_tag { false }
    monitor_changes { false }
    should_run_audit { false }
    should_log_tag_checks { true }
    consider_query_param_changes_new_tag { false }
  end
end