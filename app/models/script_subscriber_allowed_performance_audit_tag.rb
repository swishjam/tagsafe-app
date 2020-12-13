class ScriptSubscriberAllowedPerformanceAuditTag < ApplicationRecord
  belongs_to :performance_audit_script_subscriber, class_name: 'ScriptSubscriber'
  belongs_to :allowed_script_subscriber, class_name: 'ScriptSubscriber'

  validate :valid_allowed_tag

  def valid_allowed_tag
    unless performance_audit_script_subscriber.domain.script_subscriptions.include? allowed_script_subscriber
      errors.add(:base, "Cannot add an allowed tag that is not present on your domain.")
    end
  end
end