FactoryBot.define do
  factory :tag do |t|
    association :container
    association :tagsafe_js_events_batch
    # association :tag_identifying_data
    full_url { 'https://www.thirdpartytag.com/script.js' }
    url_domain { 'www.thirdpartytag.com' }
    url_path { '/script.js' }
    last_seen_at { DateTime.now }
    # load_type { 'async' }
  end

  factory :disabled_tag, parent: :tag do
    tag_preferences { create(:tag_preference, tag: self.instance, release_check_minute_interval: 0, scheduled_audit_minute_interval: 0) }
  end
end