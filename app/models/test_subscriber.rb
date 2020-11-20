class TestSubscriber < ApplicationRecord
  belongs_to :script_subscriber
  belongs_to :test
  belongs_to :expected_test_result

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_script_id, -> (script_id) { joins(:script_subscriber).where(script_subscribers: { script_id: script_id }) }
  scope :by_domain_ids, -> (domain_ids) { joins(:script_subscriber).where(script_subscribers: { domain_id: domain_ids }) }
  scope :by_domain, -> (domain) { joins(:script_subscriber).where(script_subscribers: { domain: domain })}

  def display_name
    "#{test.title} for #{script.url}#{!domain.organization.has_multiple_domains? ? " on #{domain.url}" : nil}"
  end

  def domain
    @domain ||= script_subscriber.domain
  end

  def script
    @script ||= script_subscriber.script
  end

  def evaluate_result!
    update(passed: expected_test_result.passed?(results)) if passed.nil?
  end

  def run_test_group!(script_change, execution_reason)
    GeppettoModerator::Senders::RunTestGroup.new(
      domain: domain, 
      script_change: script_change,
      test_to_run: test,
      execution_reason_id: execution_reason.id,
      test_subscriber_id: id
    ).send!
  end
end