class Domain < ApplicationRecord
  belongs_to :organization
  has_many :domain_scans
  has_many :script_subscriptions, class_name: 'ScriptSubscriber', dependent: :destroy
  has_many :scripts, through: :script_subscriptions

  validates :url, presence: true, uniqueness: true

  after_create_commit do
    scan_and_capture_domains_scripts unless Domain.skip_callbacks
  end

  def subscribe!(script, first_script_change:, initial_scan: false, monitor_changes: ENV['SHOULD_MONITOR_CHANGES_BY_DEFAULT'] == 'true', should_run_audit: ENV['SHOULD_RUN_AUDITS_BY_DEFAULT'] == 'true', allowed_third_party_tag: false, is_third_party_tag: true)
    ss = script_subscriptions.create!(
      script: script,
      first_script_change: first_script_change,
      monitor_changes: monitor_changes,
      allowed_third_party_tag: allowed_third_party_tag,
      is_third_party_tag: is_third_party_tag,
      should_run_audit: should_run_audit
    )
    AfterScriptSubscriberCreationJob.perform_later(ss, initial_scan)
  end

  def subscribed_to_script?(script)
    scripts.include? script
  end

  def allowed_third_party_tag_urls
    script_subscriptions.third_party_tags_that_shouldnt_be_blocked.collect{ |ss| ss.script.url }
  end

  def scan_and_capture_domains_scripts
    GeppettoModerator::Senders::ScanDomain.new(self, initial_scan: true).send!
  end
end