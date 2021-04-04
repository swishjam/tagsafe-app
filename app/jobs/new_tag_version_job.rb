class NewTagVersionJob < ApplicationJob
  # queue_as :tag_versiond_notifier_job

  def perform(tag_version)
    NotificationModerator::NewTagVersionNotifier.new(tag_version).notify!
    if tag_version.should_throttle_audit?
      tag_version.throttle_audit!
    else
      tag_version.run_audit!(tag_version.first_version? ? ExecutionReason.INITIAL_AUDIT : ExecutionReason.TAG_CHANGE)
    end
    DataRetention::TagVersions.new(tag_version).purge!
  end
end