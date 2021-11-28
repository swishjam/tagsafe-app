FactoryBot.define do
  factory :tag_preference do
    is_third_party_tag { true }
    is_allowed_third_party_tag { false }
    enabled { false }
    should_log_tag_checks { true }
    consider_query_param_changes_new_tag { false }
    association :tag
  end
end