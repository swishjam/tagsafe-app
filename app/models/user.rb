class User < ApplicationRecord
  class InvalidSubscribeError < StandardError; end;
  has_secure_password

  has_many :tests
  has_many :organization_users, dependent: :destroy
  has_many :organizations, through: :organization_users
  has_and_belongs_to_many :roles

  has_many :notification_subscriptions, class_name: 'NotificationSubscriber'
  has_many :script_change_notification_subscriptions, class_name: 'ScriptChangeEmailSubscriber'
  has_many :test_failed_notification_subscriptions, class_name: 'TestFailedNotificationSubscriber'
  has_many :audit_complete_notification_subscriptions, class_name: 'AuditCompleteNotificationSubscriber'

  validates :email, presence: true, uniqueness: true

  def is_admin?
    roles.include? Role.ADMIN
  end

  def can_remove_user_from_organization?(organization)
    organizations.include? organization
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