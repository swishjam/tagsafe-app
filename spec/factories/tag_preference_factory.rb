FactoryBot.define do
  factory :tag_preference do
    association :tag
    is_third_party_tag { true }
    is_allowed_third_party_tag { false }
    consider_query_param_changes_new_tag { false }
    release_check_minute_interval { 1 }
    scheduled_audit_minute_interval { 5 }
  end
end