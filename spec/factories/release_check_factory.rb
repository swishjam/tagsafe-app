FactoryBot.define do
  factory :release_check do
    association :tag
    executed_at { Time.current }
    captured_new_tag_version { false }
    bytesize_changed { false }
    hash_changed { false }
    content_is_the_same_as_a_previous_version { false }
  end
end