class ExecutedLambdaFunctionsController < LoggedInController
  def index
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    audit = Audit.find_by(uid: params[:audit_uid])
    @executed_lambda_functions = ExecutedLambdaFunction.where(parent_type: 'PerformanceAudit', parent_id: audit.individual_performance_audits.collect(&:id))
  end
end