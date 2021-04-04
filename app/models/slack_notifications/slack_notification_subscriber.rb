class SlackNotificationSubscriber < ApplicationRecord
  belongs_to :tag

  scope :still_on_site, -> { joins(:tag).where(tags: { removed_from_site_at: nil }) }
  scope :monitor_changes, -> { joins(:tag).where(tags: { monitor_changes: true }) }
  scope :should_receive_notifications, -> { monitor_changes.still_on_site }

  validates_presence_of :type, :channel

  def notify!
    raise 'Child class must define.'
  end

  def slack_client
    @slack_client ||= tag.domain.organization.slack_client
  end
end