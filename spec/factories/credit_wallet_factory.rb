FactoryBot.define do
  factory :credit_wallet do
    association :domain
    month { Time.current.month }
    total_credits_for_month { 1_000 }
  end
end