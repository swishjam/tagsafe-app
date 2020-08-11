class ScriptChange < ApplicationRecord
  belongs_to :monitored_script
  
  scope :older_than, -> (timestamp) { where("created_at < ?", timestamp).order('created_at DESC') }
  # scope :by_organization, -> (organization) { join('monitored_scripts') }

  after_create :set_monitored_script_timestamp
  after_create :notify_subscribers

  def previous_change
    # leveraging script_changes has_many scope to enforce order
    monitored_script.script_changes.older_than(created_at).limit(1).first
  end
  alias previous_result previous_change

  def set_monitored_script_timestamp
    monitored_script.update(script_last_updated_at: created_at)
  end

  def notify_subscribers
    ScriptChangedNotifierJob.perform_later(self)
  end

  def pretty_last_changed_at
    created_at.strftime("%A, %B%e @%l:%M %p (%Z)")
  end

  def megabytes
    bytes / (1024.0 * 1024.0)
  end

  def first_change?
    previous_change.nil?
  end

  def change_in_bytes
    bytes - previous_change.bytes unless previous_change.nil?
  end

  def byte_change_operator
    unless previous_change.nil?
      return 'did not change' if change_in_bytes.zero?
      change_in_bytes > 0 ? 'increased' : 'decreased'
    end
  end
end