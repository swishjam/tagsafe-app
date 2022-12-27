FactoryBot.define do
  factory :user do
    email { 'johnny@tagsafe.io' }
    password { 'password123' }
    first_name { 'Johnny' }
    last_name { 'Bravo' }
  end
end