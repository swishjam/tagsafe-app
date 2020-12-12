class ScriptsController < LoggedInController
  def index
    unless current_domain.nil?
      @script_subscriptions = current_domain.script_subscriptions
                                            .includes(:script)
                                            .order('script_subscribers.active DESC')
                                            .order('script_subscribers.removed_from_site_at ASC')
                                            .order('scripts.content_changed_at DESC')
                                            .page(params[:page] || 1).per(params[:per_page] || 9)
      @filtered_performance_audit_metric_type = PerformanceAuditMetricType.find_by(key: params[:metric_type] || 'DOMComplete')
      @active_tag_count = @script_subscriptions.is_third_party_tag.active.still_on_site.count
      # need to exclude first script changes
      @tag_change_count = 0
      # @tag_change_count = @script_subscriptions.map do |ss| 
      #   ss.script.script_changes
      #             .newer_than_or_equal_to(ss.first_script_change.created_at > Date.today.beginning_of_day ? ss.first_script_change.created_at : Date.today.beginning_of_day)
      # end.flatten!.count
    end
  end
end