
module Api
  class NotificationPreferencesController < BaseController
    def toggle_audit_complete_notification
      toggle_notification_type!(AuditCompleteNotificationSubscriber)
    end

    def toggle_test_failed_notification
      toggle_notification_type!(FailedTestNotificationSubscriber)
    end

    def toggle_script_change_notification
      toggle_notification_type!(ScriptChangeEmailSubscriber)
    end

    private
    def toggle_notification_type!(klass)
      script_subscriber = ScriptSubscriber.find(params[:script_subscriber_id])
      permitted_to_view?(script_subscriber, raise_error: true)
      already_subscribed = current_user.subscribed_to_notification?(klass, script_subscriber)
      if already_subscribed
        current_user.unsubscribe_to_notification!(klass, script_subscriber)
      else
        current_user.subscribe_to_notification!(klass, script_subscriber)
      end
      render json: {
        success: true,
        message: "You have successfully #{already_subscribed ? 'unsubscribed' : 'subscribed'} to #{script_subscriber.try_friendly_name} #{klass.friendly_name} notifications."
      }
    end
  end
end