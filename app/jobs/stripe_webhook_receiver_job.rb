class StripeWebhookReceiverJob < ApplicationJob
  def perform(stringified_stripe_event)
    StripeWebhookConsumer.new(JSON.parse(stringified_stripe_event)).process_webhook_event!
  end
end