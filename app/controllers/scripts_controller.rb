class ScriptsController < ApplicationController
  before_action :authorize!
  
  def index
    @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
                                            # .includes(lighthouse_audits: [:lighthouse_audit_results], script: [:script_changes])
  end

  def show
    @script = Script.includes(:script_changes).find(params[:id])
    permitted_to_view?(@script)
    @script_subscriber = @script.script_subscribers.find_by(domain: current_domain)
    @lighthouse_audit_metrics = LighthouseAuditMetric.by_lighthouse_audit_type(LighthouseAuditType.DELTA)
                                                      .by_script_subscriber(@script_subscriber)
                                                      .group_by{ |lar_result_metric| lar_result_metric.lighthouse_audit_metric_type.title  }
  end
end