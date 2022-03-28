FactoryBot.define do
  factory :tag_version do
    association :tag
    association :tag_check_captured_with, factory: :tag_check
    hashed_content { 'hashy123' }
    bytes { 123456 }
  end

  factory :most_recent_tag_version, parent: :tag_version do
    most_recent { true }
  end
end