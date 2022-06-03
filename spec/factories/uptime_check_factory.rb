FactoryBot.define do
  factory :uptime_check do
    association :tag
    association :uptime_check_batch
    association :uptime_region
    response_code { 200 }
    response_time_ms { 50 }
    executed_at { 1.minute.ago }
  end
end