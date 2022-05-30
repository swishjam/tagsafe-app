class CreditWalletTransactionsController < LoggedInController
  def index
    @credit_wallet = current_domain.credit_wallets.find_by(uid: params[:credit_wallet_uid])
  end
end