require 'rails_helper'

RSpec.describe BulkDebit, type: :model do
  before(:each) do
    prepare_test!
    @wallet = create(:credit_wallet, domain: @domain)
  end

  describe '#validations' do
    it 'is invalid if there is an existing record of the same type and an overlapping daterange' do
      current_time = Time.current
      ReleaseChecksBulkDebit.create!(credit_wallet: @wallet, start_date: current_time - 1.day, end_date: current_time)
      expect{
        ReleaseChecksBulkDebit.create!(credit_wallet: @wallet, start_date: current_time - 12.hours, end_date: current_time + 12.hours)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'is valid if there is an existing record of the same type with an end_date equal to the start_date of the next record' do
      existing = ReleaseChecksBulkDebit.create!(credit_wallet: @wallet, start_date: 1.hour.ago, end_date: Time.current)
      ReleaseChecksBulkDebit.create!(domain: @domain, credit_wallet: @wallet, start_date: existing.end_date, end_date: existing.end_date + 1.hour)
    end
  end

  describe '#self.debit!' do
    it 'creates a BulkDebit and an associated CreditWalletTransaction' do
      bulk_debit = ReleaseChecksBulkDebit.debit!(
        amount: 100,
        credit_wallet: @wallet,
        start_date: 1.hour.ago,
        end_date: Time.current
      )
      expect(bulk_debit.credit_wallet_transaction.reason_for_transaction).to eq(CreditWalletTransaction::Reasons.RELEASE_CHECKS)
    end
  end
end