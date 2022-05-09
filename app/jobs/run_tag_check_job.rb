class RunReleaseCheckJob < ApplicationJob
  def perform(tag)
    StepFunctionInvoker::CheckTagForNewRelease.new(tag).send!
  end
end