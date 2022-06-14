class TriggeredAlert < ApplicationRecord
  uid_prefix 'trig_alrt'
  belongs_to :alert_configuration
  belongs_to :initiating_record, polymorphic: true
  belongs_to :tag

  after_create :emit_notifications!

  validates_uniqueness_of :initiating_record_id, scope: [:initiating_record_type, :alert_configuration_id], message: Proc.new{ |triggered_alert| "This alert configuration has already been triggered for this #{triggered_alert.initiating_record_type}." }

  private

  def emit_notifications!
    alert_configuration.domain_users.each do |domain_user|
      alert_configuration.class.alert_email_klass.new(
        user: domain_user.user, 
        initiating_record: initiating_record,
        triggered_alert: self,
        alert_configuration: alert_configuration
      ).send!
      domain_user.user.broadcast_notification(
        partial: "/alert_configurations/in_app_notification",
        title: "🚨 #{alert_configuration.name}",
        image: tag.try_image_url,
        partial_locals: { 
          alert_configuration: alert_configuration,
          triggered_alert: self
        }
      )
    end
  end
end