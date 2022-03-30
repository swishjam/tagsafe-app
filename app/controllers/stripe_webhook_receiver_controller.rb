class StripeWebhookReceiverController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    event = Stripe::Webhook.construct_event(request.body.read, request.env['HTTP_STRIPE_SIGNATURE'], ENV.fetch('STRIPE_WEBHOOK_SECRET'))
    StripeWebhookReceiverJob.perform_later(event.to_json)
    head 200
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.error "Stripe Webhook Receiver Error: #{e.inspect}"
    head 400
  end
end