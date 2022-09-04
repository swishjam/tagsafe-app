class CreateCreditWalletNotifications < ActiveRecord::Migration[6.1]
  def up
    rename_column :credit_wallets, :beginning_credits, :total_credits_for_month

    create_table :credit_wallet_notifications do |t|
      t.string :uid, index: true
      t.references :credit_wallet
      t.string :type
      t.float :total_credits_for_month_at_time_of_notification
      t.float :credits_used_at_time_of_notification
      t.float :credits_remaining_at_time_of_notification
      t.timestamp :sent_at
    end
  end
end
