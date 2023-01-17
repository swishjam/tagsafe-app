class ExecutedStepFunctionsController < LoggedInController
  def index
    tag = @container.tags.find_by(uid: params[:tag_uid])
    audit = Audit.find_by(uid: params[:audit_uid])
    @executed_step_functions = ExecutedStepFunction.where(parent_type: 'PerformanceAudit', parent_id: audit.individual_performance_audits.collect(&:id))
  end
end