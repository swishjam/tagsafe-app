class ScriptSubscribersController < LoggedInController
  before_action :authorize!

  def index
    unless current_domain.nil?
      @script_subscriptions = current_domain.script_subscriptions
                                              .includes(:script)
                                              .order('script_subscribers.removed_from_site_at ASC')
                                              .order('script_subscribers.active DESC')
    end
  end

  def show
    @script_subscriber = current_domain.script_subscriptions.includes(:script).find(params[:id])
    @script_changes = @script_subscriber.script_changes
    permitted_to_view?(@script_subscriber)
    render_breadcrumbs(
      { text: 'Monitor Center', url: scripts_path }, 
      { text: "#{@script_subscriber.try_friendly_name} Details", active: true }
    )
  end

  def with_without
    @script_subscriber = ScriptSubscriber.find(params[:id])
    permitted_to_view?(@script_subscriber)
    render_breadcrumbs(
      { text: 'Monitor Center', url: scripts_path }, 
      { text: "#{@script_subscriber.try_friendly_name} Details", url: script_subscriber_path(@script_subscriber) },
      { text: "Edit #{@script_subscriber.try_friendly_name}", active: true }
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

  def update
    @script_subscriber = ScriptSubscriber.find(params[:id])
    permitted_to_view?(@script_subscriber, raise_error: true)
    if @script_subscriber.update(script_subscriber_params)
      display_toast_message("Successfully updated #{@script_subscriber.try_friendly_name}")
    else
      display_toast_error(@script_subscriber.errors.full_messages.join('\n'))
    end
    redirect_to request.referrer
  end

  private

  def script_subscriber_params
    params.require(:script_subscriber).permit(:friendly_name, :monitor_changes, :is_third_party_tag, :allowed_third_party_tag)
  end
end