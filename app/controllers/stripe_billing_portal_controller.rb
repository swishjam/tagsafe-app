class StripeBillingPortalController < LoggedInController
  def new
    session = Stripe::BillingPortal::Session.create({
      customer: current_domain.stripe_customer_id,
      return_url: "#{ENV['CURRENT_HOST']}/settings"
    })
    redirect_to session.url
  end
end