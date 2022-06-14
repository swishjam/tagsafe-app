class CreateBulkDebits < ActiveRecord::Migration[6.1]
  def up
    create_table :bulk_debits do |t|
      t.string :uid, index: true
      t.references :credit_wallet
      t.string :type
      t.float :debit_amount
      t.datetime :start_date
      t.datetime :end_date
    end
  end

  def down
    drop_table :bulk_debits
  end
end
