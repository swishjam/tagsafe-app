class NotificationSubscribersController < ApplicationController
  before_action :authorize!
  
  def index
    @monitored_scripts = current_organization.monitored_scripts
  end

  def subscribe
    @monitored_script = current_organization.monitored_scripts.includes(:notification_subscribers).find(params[:id])
    if @monitored_script
      current_user.subscribe!(@monitored_script)
      flash[:message] = "You are now subscribed to #{@monitored_script.url} changes."
    else
      flash[:error] = "You do not have access to this script."
    end
    # TODO: what's the difference between render and redirect_to
    @monitored_scripts = current_organization.monitored_scripts
    render :index
  end

  def unsubscribe
    script_notification_subcription = current_user.notification_subscribers.find_by(monitored_script_id: params[:id])
    if script_notification_subcription
      flash[:message] = "You are no longer subscribed to #{script_notification_subcription.monitored_script.url} changes."
      current_user.unsubscribe!(script_notification_subcription.monitored_script)
    else
      flash[:error] = "You do not have access to this script."
    end
    # TODO: what's the difference between render and redirect_to
    @monitored_scripts = current_organization.monitored_scripts
    render :index
  end
end