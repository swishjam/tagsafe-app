class PublishInstrumentationJob < ApplicationJob
  queue_as TagsafeQueue.CRITICAL

  def perform(instrumentation_build)
    TagsafeInstrumentationManager::InstrumentationWriter.new(instrumentation_build.container, type: 'tag-manager').write_current_instrumentation_to_cdn
    TagsafeInstrumentationManager::InstrumentationWriter.new(instrumentation_build.container, type: 'speed-optimization').write_current_instrumentation_to_cdn
    instrumentation_build.completed!
  end
end