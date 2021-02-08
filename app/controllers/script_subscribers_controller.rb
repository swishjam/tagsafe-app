class ScriptSubscribersController < LoggedInController
  before_action :authorize!

  def index
    unless current_domain.nil?
      @script_subscriptions = current_domain.script_subscriptions
                                              .includes(:script)
                                              .order('script_subscribers.removed_from_site_at ASC')
    end
  end

  def show
    @script_subscriber = current_domain.script_subscriptions.includes(:script).find(params[:id])
    @script_changes = @script_subscriber.script_changes.page(params[:page] || 1).per(params[:per_page] || 10)
    permitted_to_view?(@script_subscriber)
    render_breadcrumbs(
      { text: 'Monitor Center', url: scripts_path }, 
      { text: "#{@script_subscriber.try_friendly_name} Details", active: true }
    )
  end

  def edit
    @script_subscriber = ScriptSubscriber.find(params[:id])
    permitted_to_view?(@script_subscriber)
    render_breadcrumbs(
      { text: 'Monitor Center', url: scripts_path }, 
      { text: "#{@script_subscriber.try_friendly_name} Details", url: script_subscriber_path(@script_subscriber) },
      { text: "Edit #{@script_subscriber.try_friendly_name}", active: true }
    )
  end

  def performance_audit_settings
    @script_subscriber = ScriptSubscriber.joins(:performance_audit_preferences).find(params[:script_subscriber_id])
    permitted_to_view?(@script_subscriber)
    render_breadcrumbs(
      { text: 'Monitor Center', url: scripts_path }, 
      { text: "#{@script_subscriber.try_friendly_name} Details", url: script_subscriber_path(@script_subscriber) },
      { text: "Edit #{@script_subscriber.try_friendly_name}", active: true }
    )
  end

  def notification_settings
    @script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
    permitted_to_view?(@script_subscriber)
    if current_organization.completed_slack_setup?
      @slack_channels_options = current_organization.slack_client.get_channels['channels'].map { |channel| channel['name'] }
    end
    render_breadcrumbs(
      { text: 'Monitor Center', url: scripts_path }, 
      { text: "#{@script_subscriber.try_friendly_name} Details", url: script_subscriber_path(@script_subscriber) },
      { text: "Edit #{@script_subscriber.try_friendly_name}", active: true }
    )
  end

  def update
    @script_subscriber = ScriptSubscriber.find(params[:id])
    permitted_to_view?(@script_subscriber, raise_error: true)
    params[:script_subscriber][:friendly_name] = params[:script_subscriber][:friendly_name].empty? ? nil : params[:script_subscriber][:friendly_name]
    if @script_subscriber.update(script_subscriber_params)
      display_toast_message("Successfully updated #{@script_subscriber.try_friendly_name}")
    else
      display_toast_error(@script_subscriber.errors.full_messages.join('\n'))
    end
    redirect_to request.referrer
  end

  private

  def script_subscriber_params
    params.require(:script_subscriber).permit(:friendly_name, :throttle_minute_threshold, :monitor_changes, :is_third_party_tag, :allowed_third_party_tag, :should_run_audit, :image)
  end
end