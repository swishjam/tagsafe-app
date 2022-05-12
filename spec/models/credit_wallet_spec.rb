require 'rails_helper'

RSpec.describe CreditWallet, type: :model do
  before(:each) do
    prepare_test!
    @wallet = CreditWallet.create(domain: @domain, beginning_credits: 100, month: 1)
  end

  describe '#validations' do
    it 'raises an error if there are multiple CreditWallets with the same domain_id and month' do
      wallet_2 = CreditWallet.create(domain: @domain, beginning_credits: 100, month: 1)
      expect(@wallet.valid?).to be(true)
      expect(wallet_2.valid?).to be(false)
      expect(wallet_2.errors.full_messages[0]).to eq('Domain already has a wallet for the month of 1')
    end
    
    it 'raises an error if the wallets num_credits_remaining would go below 0' do
      expect{ @wallet.debit!(101) }.to raise_error(ActiveRecord::RecordInvalid)
      # "Cannot debit CreditWallet, only 1.0 credits available."
    end
  end

  describe '#initialize' do
    it 'sets credits_used and credits_remaining' do
      expect(@wallet.credits_used).to eq(0)
      expect(@wallet.credits_remaining).to eq(100)
    end
  end

  describe '#debit!' do
    it 'decrements credits_remaining' do
      @wallet.debit!(1)
      expect(@wallet.credits_remaining).to eq(99)
    end
    it 'increments credits_used' do
      @wallet.debit!(1)
      expect(@wallet.credits_used).to eq(1)
    end
  end

  describe '#credit!' do
    it 'increments credits_remaining' do
      @wallet.credit!(1)
      expect(@wallet.credits_remaining).to eq(101)
    end
    it 'decrements credits_used' do
      @wallet.credit!(1)
      expect(@wallet.credits_used).to eq(-1)
    end
  end

  describe '#create_transaction' do
    it 'creates a CreditWalletTransaction after a debit!' do
      expect(@wallet.transactions.count).to be(0)
      @wallet.debit!(1)
      expect(@wallet.transactions.count).to be(1)
      expect(@wallet.transactions.first.credits_used).to be(1.0)
      expect(@wallet.transactions.first.num_credits_before_transaction).to be(100.0)
      expect(@wallet.transactions.first.num_credits_after_transaction).to be(99.0)
    end

    it 'creates a CreditWalletTransaction after a credit!' do
      expect(@wallet.transactions.count).to be(0)
      @wallet.credit!(1)
      expect(@wallet.transactions.count).to be(1)
      expect(@wallet.transactions.first.credits_used).to be(-1.0)
      expect(@wallet.transactions.first.num_credits_before_transaction).to be(100.0)
      expect(@wallet.transactions.first.num_credits_after_transaction).to be(101.0)
    end

    it 'doesnt create a CreditWalletTransaction when the credits_remaining doesnt change' do
      expect(@wallet.transactions.count).to be(0)
      @wallet.update!(credits_remaining: @wallet.credits_remaining)
      expect(@wallet.transactions.count).to be(0)
    end
  end
end