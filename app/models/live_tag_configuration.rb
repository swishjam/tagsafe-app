class LiveTagConfiguration < TagConfiguration
  before_create :build_first_tag_version, if: -> { is_tagsafe_hosted }
  before_destroy { disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(release_check_minute_interval) unless tag.nil? }
  after_create { enable_aws_event_bridge_rules_for_release_check_interval_if_necessary! unless release_monitoring_disabled? }
  after_update :check_to_sync_aws_event_bridge_rules_if_necessary

  private

  def build_first_tag_version
    return unless is_tagsafe_hosted
    TagManager::TagVersionFetcher.new(tag).fetch_and_capture_first_tag_version!
  rescue TagManager::TagVersionFetcher::InvalidTagUrl, TagManager::TagVersionFetcher::InvalidFetch => e
    errors.add(:base, e.message)
  end

  private

  def check_to_sync_aws_event_bridge_rules_if_necessary
    if saved_changes['release_check_minute_interval']
      previous_release_check_minute_interval = saved_changes['release_check_minute_interval'][0]
      enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!
      disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(previous_release_check_minute_interval)
    end
  end

  def disable_aws_event_bridge_rules_if_no_release_checks_enabled_for_interval(interval)
    return if interval.zero?
    return if TagConfiguration.where(release_check_minute_interval: interval).any?
    ReleaseCheckScheduleAwsEventBridgeRule.for_interval!(interval).disable!
  end

  def enable_aws_event_bridge_rules_for_release_check_interval_if_necessary!
    return false if release_monitoring_disabled?
    ReleaseCheckScheduleAwsEventBridgeRule.for_interval!(release_check_minute_interval).enable!
  end
end