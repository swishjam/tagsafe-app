class ChangeCreditWalletToBelongToSubscriptionPlan < ActiveRecord::Migration[6.1]
  def up
    add_reference :credit_wallets, :subscription_plan
  end

  def down
    remove_reference :credit_wallets, :subscription_plan
  end
end
