class NewTagVersionJob < ApplicationJob
  def perform(tag_version)
    if Util.env_is_true('SEND_NEW_TAG_VERSION_NOTIFICATIONS_IN_NEW_TAG_VERSION_JOB')
      NotificationModerator::NewTagVersionNotifier.new(tag_version).notify!
    end
    if tag_version.should_throttle_audit?
      tag_version.throttle_audit!
    else
      tag_version.perform_audit_later_on_all_urls(tag_version.first_version? ? ExecutionReason.INITIAL_AUDIT : ExecutionReason.NEW_TAG_VERSION)
    end
    DataRetention::TagVersions.new(tag_version).purge!
  end
end