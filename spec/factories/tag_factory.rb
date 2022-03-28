FactoryBot.define do
  factory :tag do |t|
    association :domain
    association :found_on_page_url
    association :found_on_url_crawl
    # association :tag_identifying_data
    tag_preferences { create(:tag_preference, tag: self.instance) }
    full_url { 'https://www.thirdpartytag.com/script.js' }
    url_domain { 'www.thirdpartytag.com' }
    url_path { '/script.js' }
    load_type { 'async' }
    has_content { true }
    last_seen_in_url_crawl_at { 1.hour.ago }
  end

  factory :disabled_tag, parent: :tag do
    tag_preferences { create(:tag_preference, tag: self.instance, enabled: false) }
  end
end