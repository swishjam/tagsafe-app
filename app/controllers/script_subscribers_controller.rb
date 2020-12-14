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

  def edit
    @script_subscriber = ScriptSubscriber.find(params[:id])
    permitted_to_view?(@script_subscriber)
    already_allowed_script_subscriber_ids = @script_subscriber.allowed_performance_audit_tags.collect{ |allowed| allowed.allowed_script_subscriber.id }
    @selectable_allowed_third_party_tags = @script_subscriber.domain.script_subscriptions.where.not(id: [@script_subscriber.id].concat(already_allowed_script_subscriber_ids))
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
    params.require(:script_subscriber).permit(:friendly_name, :monitor_changes, :is_third_party_tag, :allowed_third_party_tag, :image)
  end
end