class TagsafeJsEventsConsumerJob < ApplicationJob
  def perform(data)
    "TagsafeJsEventsConsumers::#{data['event_type']}".constantize.new(data).consume!
  end
end