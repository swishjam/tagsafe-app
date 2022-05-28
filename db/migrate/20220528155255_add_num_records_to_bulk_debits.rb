class AddNumRecordsToBulkDebits < ActiveRecord::Migration[6.1]
  def up
    add_column :bulk_debits, :num_records_for_debited_date_range, :integer
    add_column :credit_wallets, :year, :integer
  end

  def down
    remove_column :bulk_debits, :num_records_for_debited_date_range
    remove_column :credit_wallets, :year
  end
end
