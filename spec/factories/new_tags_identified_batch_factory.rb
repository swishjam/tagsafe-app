FactoryBot.define do
  factory :tagsafe_js_events_batch do |t|
    association :container
    cloudflare_message_id { 'cldfr_msg123' }
  end
end