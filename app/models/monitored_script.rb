class MonitoredScript < ApplicationRecord
  has_many :script_subscribers
  has_many :organizations, through: :script_subscribers
  has_many :script_changes, -> { order('created_at DESC') }

  after_create :evaluate_script_details

  def most_recent_result
    script_changes.first
  end
  alias most_recent_change most_recent_result

  def evaluate_script_details
    ScriptManager::Evaluator.new(self).evaluate!
  end

  def subscribe(organization)
    script_subscribers.create(organization_id: organization.id)
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
    URI.parse(url).host
  end
end