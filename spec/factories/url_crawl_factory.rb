FactoryBot.define do
  factory :pending_url_crawl, class: 'UrlCrawl' do
    association :domain
    enqueued_at { 5.minutes.ago }
  end
end