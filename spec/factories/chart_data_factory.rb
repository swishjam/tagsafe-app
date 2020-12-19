FactoryBot.define do
  factory :chart_data do
    association :audit
    timestamp { Time.now }
    due_to_script_change { true }
  end
end