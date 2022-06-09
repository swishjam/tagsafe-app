class UpdateAlertConfigurationsSchema < ActiveRecord::Migration[6.1]
  def up
    add_column :alert_configurations, :name, :string
    add_column :alert_configurations, :type, :string
    add_column :alert_configurations, :trigger_rules, :string
    add_column :alert_configurations, :enable_for_all_tags, :boolean

    remove_column :alert_configurations, :domain_user_id
    remove_column :alert_configurations, :tag_id
    remove_column :alert_configurations, :alert_on_new_tags
    remove_column :alert_configurations, :alert_on_removed_tags
    remove_column :alert_configurations, :alert_on_new_tag_versions
    remove_column :alert_configurations, :alert_on_new_tag_version_audit_completions
    remove_column :alert_configurations, :alert_on_tagsafe_score_exceeded_thresholds
    remove_column :alert_configurations, :alert_on_slow_tag_response_times
    remove_column :alert_configurations, :tagsafe_score_threshold
    remove_column :alert_configurations, :tagsafe_score_percent_drop_threshold
    remove_column :alert_configurations, :tag_slow_response_time_ms_threshold
    remove_column :alert_configurations, :tag_slow_response_time_percent_increase_threshold
    remove_column :alert_configurations, :num_slow_responses_before_alert

    add_reference :triggered_alerts, :alert_configuration
    drop_table :triggered_alert_domain_users
    remove_column :triggered_alerts, :type
    remove_column :triggered_alerts, :triggered_reason_text

    create_table :alert_configuration_tags do |t|
      t.string :uid, index: true
      t.references :tag
      t.references :alert_configuration
    end

    create_table :alert_configuration_domain_users do |t|
      t.string :uid, index: true
      t.references :domain_user
      t.references :alert_configuration
    end
  end

  def down
    remove_column :alert_configurations, :type
    remove_column :alert_configurations, :trigger_rules
    remove_column :alert_configurations, :enable_for_all_tags, :boolean

    remove_reference :triggered_alerts, :alert_configuration

    add_reference :alert_configurations, :domain_user
    add_reference :alert_configurations, :tag
    add_column :alert_configurations, :alert_on_new_tags, :boolean
    add_column :alert_configurations, :alert_on_removed_tags, :boolean
    add_column :alert_configurations, :alert_on_new_tag_versions, :boolean
    add_column :alert_configurations, :alert_on_new_tag_version_audit_completions, :boolean
    add_column :alert_configurations, :alert_on_tagsafe_score_exceeded_thresholds, :boolean
    add_column :alert_configurations, :alert_on_slow_tag_response_times, :boolean
    add_column :alert_configurations, :tagsafe_score_threshold, :float
    add_column :alert_configurations, :tagsafe_score_percent_drop_threshold, :float
    add_column :alert_configurations, :tag_slow_response_time_ms_threshold, :float
    add_column :alert_configurations, :tag_slow_response_time_percent_increase_threshold, :float
    add_column :alert_configurations, :num_slow_responses_before_alert, :integer

    drop_table :alert_configuration_tags
    drop_table :alert_configuration_domain_users
  end
end
