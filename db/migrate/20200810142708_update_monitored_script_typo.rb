class UpdateMonitoredScriptTypo < ActiveRecord::Migration[5.2]
  def change
    rename_column :monitored_scripts, :sript_last_updated_at, :script_last_updated_at
  end
end
