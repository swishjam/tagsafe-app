class Script < ApplicationRecord
  has_many :script_subscribers, dependent: :destroy
  has_many :domains, through: :script_subscribers
  has_many :script_changes, -> { order('created_at DESC') }, dependent: :destroy
  has_many :script_checks
  
  has_many :script_change_notification_subscribers, through: :script_subscribers
  has_many :test_failed_notification_subscribers, through: :script_subscribers
  has_many :audit_complete_notification_subscribers, through: :script_subscribers
  has_many :lighthouse_audit_exceeded_threshold_notification_subscribers, through: :script_subscribers
  
  has_one_attached :image

  validates :url, presence: true, uniqueness: true
  # validate :valid_url

  scope :one_minute_interval_checks, -> { self.all }
  scope :five_minute_interval_checks, -> { self.all }
  # etc...
  scope :with_active_subscribers, -> { includes(:script_subscribers).where(script_subscribers: { active: true }) }

  def current_test_status(domain)
    most_recent_result.test_results_status(domain)
  end

  def test_subscriptions_by_domain(domain)
    test_subscriptions.by_domain(domain)
  end

  def has_tests_run?
    # this doesn't work, need to include domain scope on test runs
    most_recent_result.present?
  end

  def most_recent_result
    script_changes.where(most_recent: true).limit(1).first
  end
  alias most_recent_change most_recent_result
  alias most_recent_script_change most_recent_result

  def current_js_file_url
    most_recent_result.js_file_url
  end

  def first_eval?
    most_recent_result.nil?
  end

  # do we want this in an after_create callback? or trust the UpdateDomainsScriptsJob to be the only place to create scripts
  def evaluate_script_content
    # make sure to return the evaluator so we can read the results afterwards
    evaluator = ScriptManager::Evaluator.new(self)
    evaluator.evaluate!
    evaluator
  end

  def friendly_name
    name || url
  end

  def change_in_bytes
    most_recent_result.bytes - most_recent_result.previous_result.bytes unless most_recent_result.nil?
  end

  def pretty_last_changed_at
    most_recent_change.created_at.strftime("%A, %B%e @%l:%M %p (%Z)")
  end

  def short_name
    parsed = URI.parse(url)
    (parsed.path === "/" || parsed.path === "") ? parsed.host : parsed.path
  end

  def domain_name
    URI.parse(url).host
  end

  ###############
  # Validations #
  ###############
  def valid_url
    ScriptManager::Fetcher.new(url).fetch!
  rescue => e
    errors.add(:url, "error. Unable to connect to #{url}. URL must return a valid response.")
  end
end