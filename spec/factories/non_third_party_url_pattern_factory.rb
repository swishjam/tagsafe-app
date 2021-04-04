FactoryBot.define do
  factory :non_third_party_url_pattern do
    association :domain
    pattern { 'dontcaptureme' }
  end
end