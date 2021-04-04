FactoryBot.define do
  factory :tag_version do
    association :script
    # most_recent { true }
    hashed_content { 'hashy123' }
    bytes { 123456 }
  end
end