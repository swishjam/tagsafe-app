class FixEnabledForAllTagsDataType < ActiveRecord::Migration[6.1]
  def change
    change_column :alert_configurations, :enabled_for_all_tags, :boolean
  end
end
