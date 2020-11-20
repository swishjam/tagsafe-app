FactoryBot.define do
  factory :script_change do
    association :script
    # most_recent { true }
    hashed_content { 'hashy123' }
    bytes { 123456 }
  end
end