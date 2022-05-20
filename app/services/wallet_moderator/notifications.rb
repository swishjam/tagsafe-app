module WalletModerator
  class Notifications
    def initialize(credit_wallet)
      @credit_wallet = credit_wallet
    end

    def send_change_in_credits_notifications
      if reached_no_credit_threshold?
        NoCreditsCreditWalletNotification.create_for_wallet!(@credit_wallet)
      elsif reached_low_credit_threshold?
        LowCreditsCreditWalletNotification.create_for_wallet!(@credit_wallet)
      end
    end

    private

    def reached_low_credit_threshold?
      @credit_wallet.percent_used >= 80 && LowCreditsCreditWalletNotification.for_credit_wallet_state(@credit_wallet).nil?
    end

    def reached_no_credit_threshold?
      @credit_wallet.credits_remaining < 10 && NoCreditsCreditWalletNotification.for_credit_wallet_state(@credit_wallet).nil?
    end
  end
end