class MonitoredScript < ApplicationRecord
  has_many :notification_subscribers
  has_and_belongs_to_many :organizations
  has_many :script_changes, -> { order('created_at DESC') }

  after_create :evaluate_script_details

  validate :valid_url
  # validate :endpoint_exists

  def most_recent_result
    script_changes.first
  end
  alias most_recent_change most_recent_result

  def first_eval?
    most_recent_result.nil?
  end

  def evaluate_script_details
    # should this be on the main thread?
    ScriptManager::Evaluator.new(self).evaluate!
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

  ###############
  # Validations #
  ###############
  def valid_url
    ScriptManager::Fetcher.new(url).fetch!
  rescue => e
    errors.add(:url, "error. Unable to connect to #{url}. URL must return a valid response.")
  end
end