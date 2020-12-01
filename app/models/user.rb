class User < ApplicationRecord
  class InvalidSubscribeError < StandardError; end;
  has_secure_password

  belongs_to :organization
  has_many :tests
  has_and_belongs_to_many :roles

  has_many :notification_subscriptions, class_name: 'NotificationSubscriber'
  has_many :script_change_notification_subscriptions, class_name: 'ScriptChangeNotificationSubscriber'
  has_many :test_failed_notification_subscriptions, class_name: 'TestFailedNotificationSubscriber'
  has_many :audit_complete_notification_subscriptions, class_name: 'AuditCompleteNotificationSubscriber'
  has_many :lighthouse_audit_exceeded_threshold_notification_subscriptions, class_name: 'LighthouseAuditExceededThresholdNotificationSubscriber'

  validates :email, presence: true, uniqueness: true

  def is_admin?
    roles.include? Role.ADMIN
  end

  def invite_user_to_organization!(email_to_invite)
    UserInvite.invite!(email_to_invite, organization, self)
  end

  def subscribed_to_notification?(notification_class, script_subscriber)
    !notification_class.find_by(script_subscriber: script_subscriber, user: self).nil?
  end

  def subscribe_to_notification!(notification_class, script_subscriber)
    notification_class.create!(script_subscriber: script_subscriber, user: self)
  end

  def unsubscribe_to_notification!(notification_class, script_subscriber)
    notification_class.find_by(script_subscriber: script_subscriber, user: self).destroy!
  end
end