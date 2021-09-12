FactoryBot.define do
  factory :tag_version do
    association :tag
    # most_recent { true }
    hashed_content { 'hashy123' }
    bytes { 123456 }
  end
end