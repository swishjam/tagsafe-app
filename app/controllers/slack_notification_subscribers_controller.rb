class SlackNotificationSubscribersController < LoggedInController
  def create
    sns = SlackNotificationSubscriber.create(slack_notification_subscriber_params)
    if sns.valid?
      display_toast_message('Added Slack notification.')
    else
      display_toast_errors(sns.errors.full_messages)
    end
    redirect_to request.referrer
  end

  def destroy
    SlackNotificationSubscriber.find(params[:id]).destroy!
    display_toast_message('Removed Slack notification.')
    redirect_to request.referrer
  end

  private
  def slack_notification_subscriber_params
    params.require(:slack_notification_subscriber).permit(:script_subscriber_id, :type, :channel)
  end
end