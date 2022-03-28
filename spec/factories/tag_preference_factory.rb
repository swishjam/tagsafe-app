FactoryBot.define do
  factory :tag_preference do
    association :tag
    is_third_party_tag { true }
    is_allowed_third_party_tag { false }
    enabled { true }
    should_log_tag_checks { true }
    consider_query_param_changes_new_tag { false }
    tag_check_minute_interval { 1 }
  end
end