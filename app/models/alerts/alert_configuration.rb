class AlertConfiguration < ApplicationRecord
  belongs_to :domain
  belongs_to :domain_user
  belongs_to :tag, optional: true

  def self.for_tag(tag)
    find_by(tag: tag)
  end

  def self.create_default_for(
    domain_user,
    alert_on_new_tags: false,
    alert_on_removed_tags: false,
    alert_on_new_tag_versions: false,
    alert_on_new_tag_version_audit_completions: false,
    alert_on_slow_tag_response_times: false,
    alert_on_tagsafe_score_exceeded_thresholds: false,
    tagsafe_score_threshold: 75.0,
    tagsafe_score_percent_drop_threshold: 15.0,
    tag_slow_response_time_ms_threshold: 250,
    tag_slow_response_time_percent_increase_threshold: 100,
    num_slow_responses_before_alert: 3
  )
    create!(
      domain_user: domain_user,
      domain: domain_user.domain,
      alert_on_new_tags: alert_on_new_tags,
      alert_on_removed_tags: alert_on_removed_tags,
      alert_on_new_tag_versions: alert_on_new_tag_versions,
      alert_on_new_tag_version_audit_completions: alert_on_new_tag_version_audit_completions,
      alert_on_slow_tag_response_times: alert_on_slow_tag_response_times,
      alert_on_tagsafe_score_exceeded_thresholds: alert_on_tagsafe_score_exceeded_thresholds,
      tagsafe_score_threshold: tagsafe_score_threshold,
      tagsafe_score_percent_drop_threshold: tagsafe_score_percent_drop_threshold,
      tag_slow_response_time_ms_threshold: tag_slow_response_time_ms_threshold,
      tag_slow_response_time_percent_increase_threshold: tag_slow_response_time_percent_increase_threshold,
      num_slow_responses_before_alert: num_slow_responses_before_alert
    )
  end
end