class AddDisabledToAlertConfigurations < ActiveRecord::Migration[6.1]
  def up
    add_column :alert_configurations, :disabled, :boolean
    add_column :alert_configurations, :name, :string
    add_column :alert_configurations, :enabled_for_all_tags, :string
    add_column :alert_configurations, :created_at, :datetime, null: false
    add_column :alert_configurations, :updated_at, :datetime, null: false

    remove_column :triggered_alerts, :type
    remove_column :triggered_alerts, :triggered_reason_text

    add_column :alert_configuration_domain_users, :uid, :string, index: true
    add_column :alert_configuration_tags, :uid, :string, index: true
  end
end
