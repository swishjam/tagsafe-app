class BulkDebit < ApplicationRecord
  class << self
    attr_accessor :transaction_reason
  end

  belongs_to :credit_wallet
  has_one :credit_wallet_transaction, as: :record_responsible_for_charge

  validate :no_overlapping_timeframes

  def self.most_recent
    most_recent_first(timestamp_column: :'bulk_debits.end_date').limit(1).first
  end

  def self.debit!(amount:, credit_wallet:, num_records_for_debited_date_range:, start_date:, end_date:)
    bulk_debit = create!(
      debit_amount: amount, 
      credit_wallet: credit_wallet, 
      num_records_for_debited_date_range: num_records_for_debited_date_range, 
      start_date: start_date, 
      end_date: end_date
    )
    credit_wallet.debit!(amount, record_responsible_for_debit: bulk_debit, reason: self.transaction_reason)
    bulk_debit
  end

  private

  def no_overlapping_timeframes
    overlapping_bulk_debit = self.class.where('credit_wallet_id = ? AND start_date < ? AND end_date > ?', credit_wallet_id, start_date, start_date).limit(1).first
    if overlapping_bulk_debit.present?
      errors.add(:base, "The daterange of #{start_date.formatted_long} - #{end_date.formatted_long} would overlap with an existing #{type} (#{overlapping_bulk_debit.uid}) and would result in a double charge.")
    end
  end
end