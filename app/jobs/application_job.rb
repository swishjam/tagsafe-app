class ApplicationJob < ActiveJob::Base
  queue_as TagsafeQueue.NORMAL
end
