class ScriptSubscribersController < LoggedInController
  before_action :authorize!

  def index
    unless current_domain.nil?
      @script_subscriptions = current_domain.script_subscriptions
                                              .includes(:script, :lighthouse_preferences)
                                              .order('script_subscribers.removed_from_site_at ASC')
                                              .order('script_subscribers.active DESC')
    end
  end

  def show
    @script_subscriber = current_domain.script_subscriptions.includes(:script).find(params[:id])
    @script_changes = @script_subscriber.script.script_changes.most_recent_first
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

  def update
    @script_subscriber = ScriptSubscriber.find(params[:id])
    permitted_to_view?(@script_subscriber, raise_error: true)
    if @script_subscriber.update(script_subscriber_params)
      flash[:banner_message] = "Successfully updated #{@script_subscriber.try_friendly_name}"
    else
      flash[:banner_error] = @script_subscriber.errors.full_messages.join('\n')
    end
    redirect_to script_subscriber_path(@script_subscriber)
  end

  private

  def script_subscriber_params
    params.require(:script_subscriber).permit(:friendly_name)
  end
end