class TriggeredAlert < ApplicationRecord
  uid_prefix 'trig_alrt'
  belongs_to :alert_configuration
  belongs_to :initiating_record, polymorphic: true
  belongs_to :tag

  after_create { alert_configuration.emit_alert_triggered_notifications(self) }

  validates_uniqueness_of :initiating_record_id, scope: [:initiating_record_type, :alert_configuration_id], message: Proc.new{ |triggered_alert| "This alert configuration has already been triggered for this #{triggered_alert.initiating_record_type}." }
end