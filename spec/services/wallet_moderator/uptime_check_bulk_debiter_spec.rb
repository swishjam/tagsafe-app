require 'rails_helper'

RSpec.describe WalletModerator::UptimeCheckBulkDebiter do
  before(:each) do
    prepare_test!
    @tag = create_tag_with_associations
  end

  def create_uptime_checks(num_uptime_checks, uptime_region:, most_recent_executed_at: Time.current)
    num_uptime_checks.times do |i|
      uptime_check_batch = create(:uptime_check_batch, uptime_region: uptime_region)
      create(:uptime_check, 
        uptime_check_batch: uptime_check_batch, 
        uptime_region: uptime_region,
        tag: @tag,
        executed_at: most_recent_executed_at - i.minutes
      )
    end
  end

  describe '#debit_for_uptime_checks!' do
    it 'debits for all previous UptimeChecks within the last two months when there is no previous UptimeCheckDebits' do
      # frozen_current_time = allow(Time).to receive(:current).and_return(Time.current)
      us_east_1 = UptimeRegion.US_EAST_1
      create_uptime_checks(10, uptime_region: us_east_1)

      uptime_check_batch = create(:uptime_check_batch, uptime_region: us_east_1)
      create(:uptime_check, 
        uptime_check_batch: uptime_check_batch, 
        uptime_region: us_east_1, 
        tag: @tag,
        executed_at: 1.month.ago - 1.day
      )

      uptime_debit = WalletModerator::UptimeCheckBulkDebiter.new(@domain).debit_for_uptime_checks!
      expect(uptime_debit.num_records_for_debited_date_range).to eq(11)
      expect(uptime_debit.start_date).to eq(Time.current.beginning_of_month.last_month)
      # expect(uptime_debit.end_date).to eq(frozen_current_time)
      expect(uptime_debit.credit_wallet).to eq(@domain.credit_wallet_for_current_month_and_year)
      expect(uptime_debit.debit_amount).to eq(@domain.feature_prices_in_credits.uptime_check_price * 11)
      expect(uptime_debit.credit_wallet_transaction).to_not be(nil)
      expect(uptime_debit.credit_wallet_transaction.credits_used).to eq(uptime_debit.debit_amount)
      expect(uptime_debit.credit_wallet_transaction.reason_for_transaction).to eq('uptime_checks')
    end

    it 'debits for UptimeChecks since the most recent UptimeCheckDebits' do
      us_east_1 = UptimeRegion.US_EAST_1
      create_uptime_checks(10, uptime_region: us_east_1, most_recent_executed_at: Time.current.beginning_of_hour - 1.hour)
      
      end_date_for_previous_bulk_debit = Time.current.beginning_of_hour - 1.hour
      bulk_debit_for_previous_hour = create(:uptime_checks_bulk_debit, 
        credit_wallet: @domain.credit_wallet_for_current_month_and_year,
        num_records_for_debited_date_range: 10,
        start_date: Time.current.beginning_of_hour - 1.hour - 11.minutes,
        end_date: end_date_for_previous_bulk_debit
      )

      batch = create(:uptime_check_batch, uptime_region: us_east_1)
      uptime_check_for_current_range = create(:uptime_check, 
        uptime_check_batch: batch, 
        uptime_region: us_east_1, 
        tag: @tag,
        executed_at: 15.minutes.ago
      )

      uptime_debit = WalletModerator::UptimeCheckBulkDebiter.new(@domain).debit_for_uptime_checks!
      expect(uptime_debit.num_records_for_debited_date_range).to eq(1)
      expect(uptime_debit.start_date).to eq(end_date_for_previous_bulk_debit)
      # expect(uptime_debit.end_date).to eq(frozen_current_time)
      expect(uptime_debit.credit_wallet).to eq(@domain.credit_wallet_for_current_month_and_year)
      expect(uptime_debit.debit_amount).to eq(@domain.feature_prices_in_credits.uptime_check_price * 1)
      expect(uptime_debit.credit_wallet_transaction).to_not be(nil)
      expect(uptime_debit.credit_wallet_transaction.credits_used).to eq(uptime_debit.debit_amount)
      expect(uptime_debit.credit_wallet_transaction.reason_for_transaction).to eq('uptime_checks')
    end
  end
end