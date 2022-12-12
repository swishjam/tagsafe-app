class AddReleaseMonitoringIntervalToTags < ActiveRecord::Migration[6.1]
  def change
    add_column :tags, :release_monitoring_interval_in_minutes, :integer
  end
end
