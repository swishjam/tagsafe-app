FactoryBot.define do
  factory :tagsafe_js_event_batch, class: TagsafeJsEventBatch do
    # association :container
    association :page_url
    cloudflare_message_id { 'cldflr_xyz' }
    tagsafe_js_ts { 5.minutes.ago }
    enqueued_at { 4.minutes.ago }
  end
end