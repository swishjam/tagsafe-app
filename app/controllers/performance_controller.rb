class PerformanceController < LoggedInController
  def index
    @script_subscriptions = current_domain.script_subscriptions.is_third_party_tag.page(params[:page] || 1).per(params[:per_page] || 9)
    # @primary_delta_performance_audits = DeltaPerformanceAudit.joins(:audit)
    #                                                           .primary_audits
    #                                                           .most_recent
    #                                                           .by_script_subscriber_ids(@script_subscriptions.collect(&:id))
  end
end