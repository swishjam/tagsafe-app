class GeppettoModerator::Senders::Base
  attr_accessor :endpoint, :request_body, :domain

  def send!
    GeppettoModerator::Sender.new(endpoint, domain, request_body).send!
  end
end