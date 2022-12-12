class ContainerUser < ApplicationRecord
  belongs_to :user
  belongs_to :container
  has_many :container_user_roles, class_name: ContainerUserRole.to_s
  has_many :initiated_audits, class_name: Audit.to_s, foreign_key: :initiated_by_container_user_id
  has_many :triggered_alert_container_users
  has_many :triggered_alerts, through: :triggered_alert_container_users

  validates_uniqueness_of :user_id, scope: :container_id, message: Proc.new{ |container_user| "#{container_user.user.email} already belongs to #{container_user.container.name}."}

  scope :by_role, -> (role) { joins(:container_user_roles).where(container_user_roles: { role: role }) }
end