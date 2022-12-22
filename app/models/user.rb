class User < ApplicationRecord
  uid_prefix 'user'
  has_secure_password
  acts_as_paranoid

  has_many :container_users, dependent: :destroy
  has_many :containers, through: :container_users
  has_many :created_functional_tests, class_name: FunctionalTest.to_s, foreign_key: :created_by_user_id
  # has_many :initiated_audits, class_name: Audit.to_s, foreign_key: :initiated_by_container_user_id

  validates_presence_of :email, :password, :first_name, :last_name
  validates_uniqueness_of :email, conditions: -> { where(deleted_at: nil) }

  after_create { TagsafeEmail::Welcome.new(self).send! }

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    first_name[0] + last_name[0]
  end

  def is_user_admin?(container)
    has_role_for_container?(container, Role.USER_ADMIN)
  end

  def is_tagsafe_admin?(container)
    has_role_for_container?(container, Role.TAGSAFE_ADMIN)
  end

  def has_role_for_container?(container, role)
    ContainerUserRole.where(container_user: container_user_for(container), role: role).exists?
  end

  def container_user_for(container)
    container_users.find_by(container: container)
  end

  def belongs_to_multiple_containers?
    containers.count > 1
  end

  def belongs_to_container?(container)
    !container_user_for(container).nil?
  end

  def can_remove_user_from_container?(container)
    containers.include? container
  end

  def invite_user_to_container!(email_to_invite, container)
    UserInvite.invite!(email_to_invite, container, self)
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

  def broadcast_notification(title: nil, message: nil, partial: nil, partial_locals: {}, auto_dismiss: true, image: nil, timestamp: Time.current.strftime("%m/%d/%y @ %l:%M %P %Z"))
    broadcast_prepend_to(
      "user_#{uid}_notifications_container", 
      target: "user_#{uid}_notifications_container", 
      partial: 'partials/notification',
      locals: { 
        title: title,
        message: message, 
        partial: partial,
        image: image,
        timestamp: timestamp,
        auto_dismiss: auto_dismiss,
        partial_locals: partial_locals
      }
    )
  end
end