class RenameSubscriptionFeatureRestrictions < ActiveRecord::Migration[6.1]
  def up
    rename_table :subscription_feature_restrictions, :subscription_features_configurations
    add_column :subscription_features_configurations, :num_credits_provided_each_month, :float

    add_column :credit_wallet_transactions, :reason_for_transaction, :string
  end
end
