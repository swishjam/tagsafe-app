class SlackNotificationSubscriber < ApplicationRecord
  belongs_to :script_subscriber

  scope :still_on_site, -> { joins(:script_subscriber).where(script_subscribers: { removed_from_site_at: nil }) }
  scope :monitor_changes, -> { joins(:script_subscriber).where(script_subscribers: { monitor_changes: true }) }
  scope :should_receive_notifications, -> { monitor_changes.still_on_site }

  validates_presence_of :type, :channel

  def notify!
    raise 'Child class must define.'
  end

  def slack_client
    @slack_client ||= script_subscriber.domain.organization.slack_client
  end
end