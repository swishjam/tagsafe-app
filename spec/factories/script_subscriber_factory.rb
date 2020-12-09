FactoryBot.define do
  factory :script_subscriber do
    active { true }
    is_third_party_tag { true }
    allowed_third_party_tag { false }
    monitor_changes { true }
  end
end