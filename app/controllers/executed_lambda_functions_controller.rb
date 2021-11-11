class ExecutedLambdaFunctionsController < LoggedInController
  def index
    tag = current_domain.tags.find(params[:tag_id])
    audit = Audit.find(params[:audit_id])
    @executed_lambda_functions = ExecutedLambdaFunction.where(parent_type: 'PerformanceAudit', parent_id: audit.individual_performance_audits.collect(&:id))
  end
end