FactoryBot.define do
  factory :tag_check do
    association :tag
    captured_new_tag_version { false }
    response_time_ms { 100 }
    response_code { 200 }
  end
end