class Domain < ApplicationRecord
  belongs_to :organization
  has_many :script_subscriptions, class_name: 'ScriptSubscriber', dependent: :destroy
  has_many :scripts, through: :script_subscriptions, dependent: :destroy

  validates :url, presence: true, uniqueness: true

  after_create_commit :scan_and_capture_domains_scripts

  def subscribe!(script, active = false)
    script_subscriptions.create!(script: script, active: active)
  end

  def subscribed_to_script?(script)
    scripts.include? script
  end

  def test_subscriptions
    TestSubscriber.by_domain(self)
  end

  def test_group_runs
    TestGroupRun.by_domain(self)
  end

  def scan_and_capture_domains_scripts
    GeppettoModerator::Senders::ScanDomain.new(self).send!
  end

  def run_test_suite!
    GeppettoModerator::Senders::RunTestSuiteForDomain.new(domain).send!
  end
end