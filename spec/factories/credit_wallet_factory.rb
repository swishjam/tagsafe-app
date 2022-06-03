FactoryBot.define do
  factory :credit_wallet do
    association :domain
    month { Time.current.month }
    year { Time.current.year }
    total_credits_for_month { 1_000 }
    credits_used { 0 }
    credits_remaining { 1_000 }
  end
end