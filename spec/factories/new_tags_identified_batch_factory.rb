FactoryBot.define do
  factory :new_tags_identified_batch do |t|
    association :domain
    cloudflare_message_id { 'cldfr_msg123' }
  end
end