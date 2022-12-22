FactoryBot.define do
  factory :non_third_party_url_pattern do
    association :container
    pattern { 'dontcaptureme' }
  end
end