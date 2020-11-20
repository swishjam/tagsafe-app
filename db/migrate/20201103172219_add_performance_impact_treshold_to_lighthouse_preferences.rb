class AddPerformanceImpactTresholdToLighthousePreferences < ActiveRecord::Migration[5.2]
  def change
    add_column :lighthouse_preferences, :performance_impact_threshold, :float
  end
end
