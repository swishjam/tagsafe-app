class PublishInstrumentationJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(instrumentation_build)
    TagsafeInstrumentationManager::InstrumentationWriter.new(instrumentation_build.container).write_current_instrumentation_to_cdn
    instrumentation_build.completed!
  end
end