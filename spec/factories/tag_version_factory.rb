FactoryBot.define do
  factory :tag_version do
    association :tag
    association :release_check_captured_with, factory: :release_check
    hashed_content { 'hashy123' }
    bytes { 123456 }
  end

  factory :most_recent_tag_version, parent: :tag_version do
    most_recent { true }
  end
end