class SlackNotificationSubscriber < ApplicationRecord
  

  belongs_to :tag

  scope :still_on_site, -> { joins(:tag).where(tags: { removed_from_site_at: nil }) }
  scope :enabled, -> { joins(:tag).where(tags: { enabled: true }) }
  scope :should_receive_notifications, -> { enabled.still_on_site }

  validates_presence_of :type, :channel

  def notify!
    raise 'Child class must define.'
  end

  def slack_client
    @slack_client ||= tag.domain.slack_client
  end
end