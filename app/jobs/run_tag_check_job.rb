class RunTagCheckJob < ApplicationJob
  def perform(tag)
    tag.run_tag_check!
  end
end