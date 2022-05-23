FactoryBot.define do
  factory :release_check_batch do
    batch_uid { 'abc123' }
    minute_interval { '1' }
    num_tags_with_new_versions { 0 }
    num_tags_without_new_versions { 0 }
    executed_at { 5.minutes.ago }
    ms_to_run_check { 100 }
  end
end