class Script < ApplicationRecord
  include Rails.application.routes.url_helpers
  
  belongs_to :script_image, optional: true
  has_many :script_subscribers, dependent: :destroy
  has_many :domains, through: :script_subscribers
  has_many :script_changes, -> { order('created_at DESC') }, dependent: :destroy
  has_many :script_checks, dependent: :destroy
  
  has_many :script_change_notification_subscribers, through: :script_subscribers
  has_many :test_failed_notification_subscribers, through: :script_subscribers
  has_many :audit_complete_notification_subscribers, through: :script_subscribers

  has_many :script_changed_slack_notifications, through: :script_subscribers
  has_many :audit_completed_slack_notifications, through: :script_subscribers
  has_many :audit_complete_notification_subscribers, through: :script_subscribers
  has_many :new_tag_slack_notifications, through: :script_subscribers
  
  has_one_attached :image

  after_create :try_to_apply_script_image

  validates :url, presence: true, uniqueness: true
  # validate :valid_url

  scope :one_minute_interval_checks, -> { self.all }
  scope :five_minute_interval_checks, -> { self.all }
  # etc...
  scope :with_active_subscribers, -> { includes(:script_subscribers).where(script_subscribers: { monitor_changes: true }) }
  scope :still_on_site, -> { includes(:script_subscribers).where(script_subscribers: { removed_from_site_at: nil }) }
  scope :monitor_changes, -> { includes(:script_subscribers).where(script_subscribers: { monitor_changes: true }) }
  scope :should_run_audit, -> { includes(script_subscribers: [:performance_audit_preferences]).where(script_subscribers: { performance_audit_preferences: { should_run_audit: true }} ) }

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

  def current_js_file_path
    most_recent_result.js_file_path
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

  def try_to_apply_script_image
    ScriptImageDomainLookupPattern.find_and_apply_image_to_script(self)
  end

  def remove_script_image
    update(script_image_id: nil)
  end

  def try_image_url
    script_image ? rails_blob_url(script_image.image, host: ENV['CURRENT_HOST']) : default_image_url
    # script_image ? rails_blob_path(script_image.image, only_path: only_path) : default_image_url
  end

  def default_image_url
    'https://cdn3.iconfinder.com/data/icons/online-marketing-line-3/48/109-512.png'
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