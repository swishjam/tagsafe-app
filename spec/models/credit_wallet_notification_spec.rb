require 'rails_helper'

RSpec.describe CreditWalletNotification, type: :model do
  before(:each) do
    prepare_test!
    @wallet = create(:credit_wallet, domain: @domain)
  end

  describe '#validations' do
    it 'raises an error if a CreditWalletNotification already exists for the same CreditWallet with the same credit attributes' do
      LowCreditsCreditWalletNotification.create_for_wallet!(@wallet)
      expect{ LowCreditsCreditWalletNotification.create_for_wallet!(@wallet) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#callbacks' do
    it 'calls send_emails! after_create' do
      expect_any_instance_of(LowCreditsCreditWalletNotification).to receive(:send_emails!)
      LowCreditsCreditWalletNotification.create_for_wallet!(@wallet)
    end
  end

  describe '#self.for_credit_wallet_state' do
    it 'returns any existing CreditWalletNotifications for the provided wallet with the same `total_credits_for_month_at_time_of_notification`' do
      expect(LowCreditsCreditWalletNotification.for_credit_wallet_state(@wallet)).to be(nil)
      
      notif = LowCreditsCreditWalletNotification.create_for_wallet!(@wallet)
      expect(LowCreditsCreditWalletNotification.for_credit_wallet_state(@wallet)).to eq(notif)

      @wallet.update_columns(total_credits_for_month: @wallet.total_credits_for_month * 2, credits_remaining: @wallet.credits_remaining * 2)
      expect(LowCreditsCreditWalletNotification.for_credit_wallet_state(@wallet)).to be(nil)
    end
  end

  describe '#self.create_for_wallet' do 
    it 'creates a `LowCreditsCreditWalletNotification` for the specified wallet and passes through the wallets current attributes' do
      notif = LowCreditsCreditWalletNotification.create_for_wallet(@wallet)
      expect(notif.credit_wallet).to eq(@wallet.total_credits_for_month)
      expect(notif.total_credits_for_month_at_time_of_notification).to eq(@wallet.total_credits_for_month)
      expect(notif.credits_used_at_time_of_notification).to eq(@wallet.credits_used)
      expect(notif.credits_remaining_at_time_of_notification).to eq(@wallet.credits_remaining)
      expect(notif.sent_at).to not_be(nil)
    end
  end

  describe '#send_emails!' do
    it 'loops through the Domain\'s DomainUsers with the `UserAdmin` role and calls `send!` with super classes `tagsafe_email_klass` attr_accessor' do
      notif = LowCreditsCreditWalletNotification.create_for_wallet(@wallet)

      domain_user_admin = @domain.domain_users.first
      Role.USER_ADMIN.apply_to_domain_user(domain_user_admin)
      
      expect(LowCreditsCreditWalletNotification.tagsafe_email_klass).to receive(:new).with(domain_user_admin.user, @wallet).and_call_original
      expect_any_instance_of(LowCreditsCreditWalletNotification.tagsafe_email_klass).to receive(:send!)

      notif.send(:send_emails!)
    end
  end
end