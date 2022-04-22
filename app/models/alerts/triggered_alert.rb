class TriggeredAlert < ApplicationRecord
  belongs_to :initiating_record, polymorphic: true
  belongs_to :tag
  has_many :triggered_alert_domain_users, dependent: :destroy
  has_many :alerted_domain_users, through: :triggered_alert_domain_users, source: :domain_user

  after_create_commit :enqueue_notifications_to_be_sent!

  class << self
    attr_accessor :send_notification_in_new_job
  end

  self.send_notification_in_new_job = true

  def enqueue_notifications_to_be_sent!
    self.class.send_notification_in_new_job ? EmitAlertNotificationsJob.perform_later(self) : EmitAlertNotificationsJob.perform_now(self)
  end

  def friendly_type
    self.class.to_s.gsub('Alert', '').split(/(?=[A-Z])/).join(' ')
  end

  def tag_specific_alert_configuration_or_default(domain_user)
    domain_user.tag_alert_configurations.for_tag(tag) || domain_user.domain_alert_configuration
  end

  def send_alert_notification_if_necessary!(alert_config)
    raise "`send_alert_notification_if_necessary!` is not defined, #{self.class.to_s} subclass must implement it."
  end

  def send_email_alert!
    raise "`send_email_alert!` is not defined, #{self.class.to_s} subclass must implement it."
  end
end