FactoryBot.define do
  factory :organization do
    name { 'Test Organization' }
    maximum_active_script_subscriptions { 5 }
  end
end