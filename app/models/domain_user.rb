class DomainUser < ApplicationRecord
  belongs_to :user
  belongs_to :domain
  has_many :domain_user_roles, class_name: DomainUserRole.to_s
  has_many :initiated_audits, class_name: Audit.to_s, foreign_key: :initiated_by_domain_user_id
  has_many :triggered_alert_domain_users
  has_many :triggered_alerts, through: :triggered_alert_domain_users

  validates_uniqueness_of :user_id, scope: :domain_id, message: Proc.new{ |domain_user| "#{domain_user.user.email} already belongs to #{domain_user.domain.url}."}

  scope :by_role, -> (role) { joins(:domain_user_roles).where(domain_user_roles: { role: role }) }
end