class SlackNotificationsController < LoggedInController
  def create
    SlackNotification.create(slack_notification_params)
    display_toast_message('Added Slack notification.')
    redirect_to request.referrer
  end

  def destroy
    SlackNotification.find(params[:id]).destroy!
    display_toast_message('Removed Slack notification.')
    redirect_to request.referrer
  end

  private
  def slack_notification_params
    params.require(:slack_notification).permit(:script_subscriber_id, :type, :channel)
  end
end