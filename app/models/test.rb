class Test < ApplicationRecord
  belongs_to :created_by_user, class_name: 'User', foreign_key: :created_by_user_id
  belongs_to :created_by_organization, class_name: 'Organization', foreign_key: :created_by_organization_id
  has_and_belongs_to_many :domains
  # has_and_belongs_to_many :scripts
  has_many :test_runs
  has_many :test_subscribers

  scope :default_tests, -> { where(default_test: true) }

  DEFAULT_EXPECTED_TEST_RESULT_DICTIONARY = {
    30 => 1,
    31 => 2
  }

  def subscribe_script_subscriber!(script_subscriber, active: true)
    test_subscribers.create!(script_subscriber: script_subscriber, active: active)
  end

  def default_expected_test_result
    # this is not chill
    ExpectedTestResult.find(DEFAULT_EXPECTED_TEST_RESULT_DICTIONARY[id])
  end
  
  def run_standalone_test(domain)
    GeppettoModerator::Senders::RunStandaloneTest.new(
      domain: domain, 
      test_to_run: self
    ).send!
  end
end