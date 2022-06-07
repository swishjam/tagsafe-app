class DomainUser < ApplicationRecord
  belongs_to :user
  belongs_to :domain
  has_many :domain_user_roles, class_name: DomainUserRole.to_s
  
  has_many :initiated_audits, class_name: Audit.to_s, foreign_key: :initiated_by_domain_user_id
  
  has_many :alert_configurations
  has_one :domain_alert_configuration, -> { where(tag_id: nil) }, class_name: AlertConfiguration.to_s
  has_many :tag_alert_configurations, -> { where.not(tag_id: nil) }, class_name: AlertConfiguration.to_s
  
  has_many :alert_configuration_domain_users
  has_many :alert_configurations, through: :alert_configuration_domain_users

  has_many :triggered_alert_domain_users
  has_many :triggered_alerts, through: :triggered_alert_domain_users

  validates_uniqueness_of :user_id, scope: :domain_id, message: Proc.new{ |domain_user| "#{domain_user.user.email} already belongs to #{domain_user.domain.url}."}

  after_create :add_defaults

  scope :by_role, -> (role) { joins(:domain_user_roles).where(domain_user_roles: { role: role }) }

  def add_defaults
    AlertConfiguration.create_default_for(self)
  end
end