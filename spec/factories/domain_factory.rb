FactoryBot.define do
  factory :domain do
    url { 'https://www.test.com' }
    is_generating_third_party_impact_trial { false }
  end
  factory :generating_third_party_impact_trial_domain, class: Domain.to_s do
    url { 'https://www.test-test.com' }
    is_generating_third_party_impact_trial { true }
  end
  factory :domain_2, class: 'Domain' do
    url { 'https://www.domain.com' }
    is_generating_third_party_impact_trial { false }
  end
end