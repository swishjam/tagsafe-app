
module Api
  class NotificationPreferencesController < BaseController
    def toggle_audit_complete_notification
      toggle_notification_type!(AuditCompleteNotificationSubscriber)
    end

    def toggle_tag_version_notification
      toggle_notification_type!(NewTagVersionEmailSubscriber)
    end

    private
    def toggle_notification_type!(klass)
      tag = Tag.find(params[:tag_id])
      permitted_to_view?(tag, raise_error: true)
      already_subscribed = current_user.subscribed_to_notification?(klass, tag)
      if already_subscribed
        current_user.unsubscribe_to_notification!(klass, tag)
      else
        current_user.subscribe_to_notification!(klass, tag)
      end
      render json: {
        success: true,
        message: "You have successfully #{already_subscribed ? 'unsubscribed' : 'subscribed'} to #{tag.try_friendly_name} #{klass.friendly_name} notifications."
      }
    end
  end
end