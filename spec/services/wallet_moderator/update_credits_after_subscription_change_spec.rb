require 'rails_helper'

RSpec.describe WalletModerator::UpdateCreditsAfterSubscriptionChange do
  before(:each) do
    prepare_test!
  end

  describe '#update!' do
    it 'updates the wallets total_credits_for_month to the new subscription package, and the credits_remaining based on what was consumed so far' do
      subscription_features_configuration = create(:subscription_features_configuration, domain: @domain, num_credits_provided_each_month: 100_000)
      wallet = create(:credit_wallet, domain: @domain, total_credits_for_month: 100, credits_remaining: 100, credits_used: 0)
      
      WalletModerator::UpdateCreditsAfterSubscriptionChange.new(wallet).update!
      
      expect(wallet.total_credits_for_month).to eq(subscription_features_configuration.num_credits_provided_each_month)
      expect(wallet.credits_used).to eq(0)
      expect(wallet.credits_remaining).to eq(subscription_features_configuration.num_credits_provided_each_month)
    end

    it 'brings the wallet\'s credits_remaining negative if the new subscription package comes with less credits than what has been consumed in the current wallet so far this month' do
      subscription_features_configuration = create(:subscription_features_configuration, domain: @domain, num_credits_provided_each_month: 100)
      wallet = create(:credit_wallet, domain: @domain, total_credits_for_month: 200, credits_used: 150, credits_remaining: 50)

      WalletModerator::UpdateCreditsAfterSubscriptionChange.new(wallet).update!

      expect(wallet.total_credits_for_month).to eq(subscription_features_configuration.num_credits_provided_each_month)
      expect(wallet.credits_used).to eq(150)
      total_credits_used_before_new_subscription = 150
      new_subscriptions_total_credits_per_month = 100
      expect(wallet.credits_remaining).to eq(new_subscriptions_total_credits_per_month - total_credits_used_before_new_subscription)
    end
  end
end