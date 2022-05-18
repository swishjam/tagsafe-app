class AddCreditTables < ActiveRecord::Migration[6.1]
  def up
    create_table :credit_wallets do |t|
      t.string :uid, index: true
      t.references :domain
      t.integer :month
      t.integer :beginning_credits
      t.float :credits_used
      t.float :credits_remaining
      t.datetime :disabled_at
      t.timestamps
    end

    create_table :credit_wallet_transactions do |t|
      t.string :uid, index: true
      t.references :credit_wallet
      t.references :record_responsible_for_charge, polymorphic: true, index: { name: :index_cwt_record_for_charge }
      t.float :credits_used
      t.float :num_credits_before_transaction
      t.float :num_credits_after_transaction
      t.timestamps
    end

    create_table :feature_prices_in_credits do |t|
      t.string :uid, index: true
      t.references :domain
      t.float :automated_performance_audit_price
      t.float :automated_test_run_price
      t.float :manual_performance_audit_price
      t.float :manual_test_run_price
      t.float :puppeteer_recording_price
      t.float :speed_index_filmstrip_price
      t.float :resource_waterfall_price
      t.float :uptime_check_price
      t.float :release_check_price
      t.timestamps
    end

    remove_column :subscription_feature_restrictions, :manual_performance_audits_included_per_month
    remove_column :subscription_feature_restrictions, :manual_test_runs_included_per_month
    remove_column :subscription_feature_restrictions, :automated_performance_audits_included_per_month
    remove_column :subscription_feature_restrictions, :automated_test_runs_included_per_month
    remove_column :subscription_feature_restrictions, :uptime_checks_included_per_month
    remove_column :subscription_feature_restrictions, :release_checks_included_per_month
  end

  def down
    drop_table :credit_wallets
    drop_table :credit_wallet_transactions
    drop_table :feature_prices_in_credits

    add_column :subscription_feature_restrictions, :manual_performance_audits_included_per_month, :integer
    add_column :subscription_feature_restrictions, :manual_test_runs_included_per_month, :integer
    add_column :subscription_feature_restrictions, :automated_performance_audits_included_per_month, :integer
    add_column :subscription_feature_restrictions, :automated_test_runs_included_per_month, :integer
    add_column :subscription_feature_restrictions, :uptime_checks_included_per_month, :integer
    add_column :subscription_feature_restrictions, :release_checks_included_per_month, :integer
  end
end
