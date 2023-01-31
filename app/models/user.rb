class User < ApplicationRecord
  uid_prefix 'user'
  has_secure_password
  acts_as_paranoid

  has_many :container_users, dependent: :destroy
  has_many :containers, through: :container_users
  has_many :containers_created, class_name: Container.to_s, foreign_key: :created_by_user_id
  has_many :created_functional_tests, class_name: FunctionalTest.to_s, foreign_key: :created_by_user_id
  # has_many :initiated_audits, class_name: Audit.to_s, foreign_key: :initiated_by_container_user_id

  validates_presence_of :email, :first_name, :last_name
  validates :password, length: { minimum: 8 }
  validates_uniqueness_of :email, conditions: -> { where(deleted_at: nil) }
  validate :only_tagsafe_emails_can_become_tagsafe_admins

  after_create { TagsafeEmail::Welcome.new(self).send! }
  after_create { TagsafeEmail::Generic.new(to_email: 'founders@tagsafe.io', subject: 'New user', body: email).send! }

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    first_name[0] + last_name[0]
  end

  def is_user_admin?(container)
    has_role_for_container?(container, Role.USER_ADMIN)
  end

  def is_tagsafe_admin?
    is_tagsafe_admin
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

  def broadcast_notification(message:, title: nil, cta_url: nil, cta_text: nil, auto_dismiss: true, image: nil, timestamp: Time.current.formatted_short)
    broadcast_prepend_to(
      "user_#{uid}_notifications_container", 
      target: "user_#{uid}_notifications_container", 
      partial: 'partials/notification',
      locals: { 
        title: title,
        message: message, 
        cta_url: cta_url,
        cta_text: cta_text,
        image: image,
        timestamp: timestamp,
        auto_dismiss: auto_dismiss,
      }
    )
  end

  private

  def only_tagsafe_emails_can_become_tagsafe_admins
    if is_tagsafe_admin && !email.ends_with?('@tagsafe.io')
      errors.add(:base, 'Unable to update user.')
    end
  end
end