class Domain < ApplicationRecord
  belongs_to :organization
  has_many :domain_scans
  has_many :script_subscriptions, class_name: 'ScriptSubscriber', dependent: :destroy
  has_many :scripts, through: :script_subscriptions

  validates :url, presence: true, uniqueness: true

  after_create_commit do
    scan_and_capture_domains_scripts unless Domain.skip_callbacks
  end

  def subscribe!(script, first_script_change:, initial_scan: false, active: false, monitor_changes: true, allowed_third_party_tag: false, is_third_party_tag: true)
    ss = script_subscriptions.create!(
      script: script,
      first_script_change: first_script_change,
      active: active, 
      monitor_changes: monitor_changes,
      allowed_third_party_tag: allowed_third_party_tag,
      is_third_party_tag: is_third_party_tag
    )
    AfterScriptSubscriberCreationJob.perform_later(ss, initial_scan)
  end

  def subscribed_to_script?(script)
    scripts.include? script
  end

  def allowed_third_party_tag_urls
    script_subscriptions.third_party_tags_that_shouldnt_be_blocked.collect{ |ss| ss.script.url }
  end

  def test_subscriptions
    TestSubscriber.by_domain(self)
  end

  def test_group_runs
    TestGroupRun.by_domain(self)
  end

  def scan_and_capture_domains_scripts
    GeppettoModerator::Senders::ScanDomain.new(self, initial_scan: true).send!
  end

  def run_test_suite!
    GeppettoModerator::Senders::RunTestSuiteForDomain.new(domain).send!
  end
end