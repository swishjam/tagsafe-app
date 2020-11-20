FactoryBot.define do
  factory :domain do
    association :organization
    url { 'https://www.test.com' }
  end
  factory :domain_2, class: 'Domain' do
    association :organization
    url { 'https://www.domain.com' }
  end
end