module WalletModerator
  class Notifications
    def initialize(credit_wallet)
      @credit_wallet = credit_wallet
    end

    def send_change_in_credits_notifications
      send_low_credit_notification_if_necessary
      send_no_credit_notification_if_necessary
    end

    private

    def send_low_credit_notification_if_necessary
      if @credit_wallet.percent_used >= 80
        already_sent_notification_for_threshold = LowCreditsCreditWalletNotification.for_credit_wallet_state(@credit_wallet).present?
        return if already_sent_notification_for_threshold
        LowCreditsCreditWalletNotification.create_for_wallet!(@credit_wallet)
      end
    end

    def send_no_credit_notification_if_necessary
      if @credit_wallet.credits_remaining < 10
        already_sent_notification_for_threshold = NoCreditsCreditWalletNotification.for_credit_wallet_state(@credit_wallet).present?
        return if already_sent_notification_for_threshold
        NoCreditsCreditWalletNotification.create_for_wallet!(@credit_wallet)
      end
    end
  end
end