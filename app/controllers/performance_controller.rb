class PerformanceController < LoggedInController
  def index
    @primary_delta_performance_audits = DeltaPerformanceAudit.joins(:audit)
                                                              .primary_audits
                                                              .most_recent
                                                              .by_script_subscriber_ids(current_domain.script_subscriptions.is_third_party_tag.collect(&:id))
    @script_subscriptions = current_domain.script_subscriptions.is_third_party_tag
  end
end