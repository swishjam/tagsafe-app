FactoryBot.define do
  factory :pending_url_crawl, class: UrlCrawl.to_s do
    association :domain
    association :page_url
    enqueued_at { 5.minutes.ago }
  end

  factory :completed_url_crawl, class: UrlCrawl.to_s, aliases: [:url_crawl], parent: :pending_url_crawl do
    completed_at { 1.minute.ago }
    seconds_to_complete { 4.minutes }
    num_first_party_bytes { 100 }
    num_third_party_bytes { 200 }
    lambda_response_received_at { 1.minute.ago }
  end
end