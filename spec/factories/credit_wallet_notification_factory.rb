FactoryBot.define do
  factory :credit_wallet_notification do
    association :wallet
    type { 'LowCreditsCreditWalletNotification' }
    total_credits_for_month_at_time_of_notification { 100 }
    credits_used_at_time_of_notification { 80 }
    credits_remaining_at_time_of_notification { 20 }
    sent_at { Time.current }
  end
end