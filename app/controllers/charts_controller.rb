class ChartsController < ApplicationController
  layout false

  def admin_audit_performance
    chart_data_getter = ChartHelper::AdminAuditPerformanceData.new
    render json: chart_data_getter.get_performance_data
  end

  def admin_executed_step_functions
    render json: ChartHelper::AdminExecutedStepFunctionsData.new.chart_data
  end
end