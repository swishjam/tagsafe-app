FactoryBot.define do
  factory :uptime_check_batch do
    association :uptime_region
    batch_uid { 'xyz789' }
    num_tags_checked { 2 }
    executed_at { 5.minutes.ago }
    ms_to_run_check { 100 }
  end
end