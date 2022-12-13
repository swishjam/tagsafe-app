FactoryBot.define do
  factory :page_url do
    association :container
    full_url { 'https://www.test.com/path' }
  end
end