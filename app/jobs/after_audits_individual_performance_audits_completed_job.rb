class AfterAuditsIndividualPerformanceAuditsCompletedJob < ApplicationJob
  def perform(audit)
    audit.create_delta_performance_audit!
  end
end