FactoryBot.define do
  factory :page_url do
    association :domain
    full_url { 'https://www.test.com/path' }
    should_scan_for_tags { true }
  end
end