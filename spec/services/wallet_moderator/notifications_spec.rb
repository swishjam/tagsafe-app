require 'rails_helper'

RSpec.describe WalletModerator::Notifications do
  before(:each) do
    prepare_test!
    @wallet = create(:credit_wallet, domain: @domain)
    @notifier = WalletModerator::Notifications.new(@wallet)
  end

  describe '#send_low_credit_notification_if_necessary' do
    it 'doesn\'t create a LowCreditsCreditWalletNotification if it is not at least 80% used' do
      @wallet.update_columns(total_credits_for_month: 100, credits_remaining: 21, credits_used: 79)
      expect(LowCreditsCreditWalletNotification).to_not receive(:for_credit_wallet_state)
      expect(LowCreditsCreditWalletNotification).to_not receive(:create_for_wallet!)
      @notifier.send(:send_low_credit_notification_if_necessary)
    end

    it 'doesn\'t create a LowCreditsCreditWalletNotification if one has already been sent for the wallet\'s state despite it meeting the threshold' do
      @wallet.update_columns(total_credits_for_month: 100, credits_remaining: 19, credits_used: 81)
      LowCreditsCreditWalletNotification.create_for_wallet!(@wallet)
      expect(LowCreditsCreditWalletNotification).to receive(:for_credit_wallet_state).with(@wallet).and_call_original
      expect(LowCreditsCreditWalletNotification).to_not receive(:create_for_wallet!)
      @notifier.send(:send_low_credit_notification_if_necessary)
    end

    it 'creates a LowCreditsCreditWalletNotification if percent_used >= 80 one has not already been sent for the wallet\'s state' do
      @wallet.update_columns(total_credits_for_month: 100, credits_remaining: 19, credits_used: 81)
      expect(LowCreditsCreditWalletNotification).to receive(:for_credit_wallet_state).with(@wallet).and_call_original
      expect(LowCreditsCreditWalletNotification).to receive(:create_for_wallet!)
      @notifier.send(:send_low_credit_notification_if_necessary)
    end
  end

  describe '#send_no_credit_notification_if_necessary' do
    it 'doesn\'t create a NoCreditsCreditWalletNotification if there are not < 10 credits remaining' do
      @wallet.update_columns(total_credits_for_month: 100, credits_remaining: 10, credits_used: 90)
      expect(NoCreditsCreditWalletNotification).to_not receive(:for_credit_wallet_state)
      expect(NoCreditsCreditWalletNotification).to_not receive(:create_for_wallet!)
      @notifier.send(:send_no_credit_notification_if_necessary)
    end

    it 'doesn\'t create a NoCreditsCreditWalletNotification if one has already been sent for the wallet\'s state despite it meeting the threshold' do
      @wallet.update_columns(total_credits_for_month: 100, credits_remaining: 9, credits_used: 91)
      NoCreditsCreditWalletNotification.create_for_wallet!(@wallet)
      expect(NoCreditsCreditWalletNotification).to receive(:for_credit_wallet_state).with(@wallet).and_call_original
      expect(NoCreditsCreditWalletNotification).to_not receive(:create_for_wallet!)
      @notifier.send(:send_no_credit_notification_if_necessary)
    end

    it 'creates a NoCreditsCreditWalletNotification if credits_remaining is < 10 and one has not already been sent for the wallet\'s state' do
      @wallet.update_columns(total_credits_for_month: 100, credits_remaining: 9, credits_used: 91)
      expect(NoCreditsCreditWalletNotification).to receive(:for_credit_wallet_state).with(@wallet).and_call_original
      expect(NoCreditsCreditWalletNotification).to receive(:create_for_wallet!)
      @notifier.send(:send_no_credit_notification_if_necessary)
    end
  end
end