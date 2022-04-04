class RunTagCheckJob < ApplicationJob
  def perform(tag)
    LambdaFunctionInvoker::CheckTagForNewRelease.new(tag).send!
  end
end