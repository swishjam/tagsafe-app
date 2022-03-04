class User < ApplicationRecord
  uid_prefix 'user'
  has_secure_password
  acts_as_paranoid

  has_many :organization_users, dependent: :destroy
  has_many :organizations, through: :organization_users
  # has_and_belongs_to_many :roles
  has_many :roles_users, class_name: RoleUser.to_s, dependent: :destroy
  has_many :roles, through: :roles_users
  has_many :created_functional_tests, class_name: FunctionalTest.to_s, foreign_key: :created_by_user_id
  has_many :initiated_audits, class_name: Audit.to_s, foreign_key: :initiated_by_user_id

  has_many :email_notification_subscriptions, class_name: 'EmailNotificationSubscriber'
  has_many :new_tag_version_notification_subscriptions, class_name: 'NewTagVersionEmailSubscriber'
  has_many :audit_complete_notification_subscriptions, class_name: 'AuditCompleteNotificationSubscriber'

  validates :email, presence: true, uniqueness: true

  after_create :send_welcome_email

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    first_name[0] + last_name[0]
  end

  def is_user_admin?
    roles.include? Role.USER_ADMIN
  end

  def is_tagsafe_admin?
    roles.include? Role.TAGSAFE_ADMIN
  end

  def belongs_to_multiple_organizations?
    organizations.count > 1
  end

  def send_welcome_email
    # TODO: need to update SendGrid template
    # TagSafeMailer.send_welcome_email(self)
  end

  def can_remove_user_from_organization?(organization)
    organizations.include? organization
  end

  def invite_user_to_organization!(email_to_invite, organization)
    UserInvite.invite!(email_to_invite, organization, self)
  end

  def subscribed_to_notification?(notification_class, tag)
    !notification_class.find_by(tag: tag, user: self).nil?
  end

  def subscribe_to_notification!(notification_class, tag)
    notification_class.create!(tag: tag, user: self)
  end

  def unsubscribe_to_notification!(notification_class, tag)
    notification_class.find_by(tag: tag, user: self).destroy!
  end

  # def broadcast_notification(msg, notification_type: 'info', image: nil, error: false)
  def broadcast_notification(message: nil, partial: nil, partial_locals: {}, image: nil, timestamp: nil)
    broadcast_prepend_to(
      "#{id}_user_notifications_container", 
      target: "#{id}_user_notifications_container", 
      partial: 'partials/notification',
      locals: { 
        message: message, 
        partial: partial,
        image: image,
        timestamp: timestamp,
        partial_locals: partial_locals
      }
    )
  end
end