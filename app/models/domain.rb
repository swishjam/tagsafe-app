class Domain < ApplicationRecord
  belongs_to :organization
  has_many :domain_scans
  has_many :script_subscriptions, class_name: 'ScriptSubscriber', dependent: :destroy
  has_many :scripts, through: :script_subscriptions

  validates :url, presence: true, uniqueness: true

  after_create_commit do
    scan_and_capture_domains_scripts(true) unless Domain.skip_callbacks
  end

  def subscribe!(
    script, 
    first_script_change:, 
    initial_scan: false, 
    monitor_changes: ENV['SHOULD_MONITOR_CHANGES_BY_DEFAULT'] == 'true', 
    should_run_audit: ENV['SHOULD_RUN_AUDITS_BY_DEFAULT'] == 'true', 
    allowed_third_party_tag: false, 
    is_third_party_tag: true,
    script_change_retention_count: (ENV['DEFAULT_SCRIPT_CHANGE_RETENTION_COUNT'] || '500').to_i,
    script_check_retention_count: (ENV['DEFAULT_SCRIPT_CHECK_RETENTION_COUNT'] || '14400').to_i # 10 days worth when checking every minute
    )
    ss = script_subscriptions.create!(
      script: script,
      first_script_change: first_script_change,
      monitor_changes: monitor_changes,
      allowed_third_party_tag: allowed_third_party_tag,
      is_third_party_tag: is_third_party_tag,
      should_run_audit: should_run_audit,
      script_check_retention_count: script_check_retention_count,
      script_change_retention_count: script_change_retention_count
    )
    AfterScriptSubscriberCreationJob.perform_later(ss) unless initial_scan
  end

  def subscribed_to_script?(script)
    scripts.include? script
  end

  def allowed_third_party_tag_urls
    script_subscriptions.third_party_tags_that_shouldnt_be_blocked.collect{ |ss| ss.script.url }
  end

  def scan_and_capture_domains_scripts(initial_scan = false)
    GeppettoModerator::Senders::ScanDomain.new(self, initial_scan: initial_scan).send!
  end
end