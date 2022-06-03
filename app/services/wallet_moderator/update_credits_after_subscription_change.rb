module WalletModerator
  class UpdateCreditsAfterSubscriptionChange
    class << self
      def update!(wallet)
        new_credits_for_month = total_credits_for_month(wallet)
        Rails.logger.info "WalletModerator::UpdateCreditsAfterSubscriptionChange - updating CreditWallet #{wallet.uid} total_credits_for_month from #{wallet.total_credits_for_month} to #{new_credits_for_month}"
        wallet.update!(
          total_credits_for_month: new_credits_for_month,
          credits_remaining: new_credits_for_month - wallet.credits_used
        )
      end

      private

      def total_credits_for_month(wallet)
        wallet.domain.subscription_features_configuration.num_credits_provided_each_month
      end
    end
  end
end