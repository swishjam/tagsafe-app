FactoryBot.define do
  factory :tag do |t|
    association :container
    association :tagsafe_js_event_batch
    # association :tag_identifying_data
    full_url { 'https://www.thirdpartytag.com/script.js' }
    url_hostname { 'www.thirdpartytag.com' }
    url_path { '/script.js' }
    last_seen_at { DateTime.now }
    load_type { 'async' }
  end
end