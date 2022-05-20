module WalletModerator
  class UpdateCreditsAfterSubscriptionChange
    def initialize(wallet)
      @wallet = wallet
    end

    def update!
      Rails.logger.info "WalletModerator::UpdateCreditsAfterSubscriptionChange - updating CreditWallet #{@wallet.uid} total_credits_for_month from #{@wallet.total_credits_for_month} to #{total_credits_for_month}"
      @wallet.update!(
        total_credits_for_month: total_credits_for_month,
        credits_remaining: total_credits_for_month - @wallet.credits_used
      )
    end

    def total_credits_for_month
      @wallet.domain.subscription_features_configuration.num_credits_provided_each_month
    end
  end
end