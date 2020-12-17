class LintResultsController < LoggedInController
  def global
    @script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(@script_subscriber)
    # @script_changes = current_domain.script_subscriptions.collect
    # .script_changes.joins(:script_change_lints)
  end

  def index
    @script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(@script_subscriber)
    @script_change = ScriptChange.find(params[:script_change_id])
    @lints = @script_subscriber.lint_results_for_script_change(@script_change).page(params[:page] || 1).per(params[:per_page] || 25)
    render_breadcrumbs(
      { text: 'Monitor Center', url: scripts_path },
      { text: "#{@script_subscriber.try_friendly_name} Details", url: script_subscriber_path(@script_subscriber) },
      { text: 'JS Violations', active: true }
    )
  end
end