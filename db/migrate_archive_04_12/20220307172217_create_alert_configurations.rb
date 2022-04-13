class CreateAlertConfigurations < ActiveRecord::Migration[6.1]
  def up
    create_table :alert_configurations do |t|
      t.string :uid, index: true
      t.references :domain_user
      t.references :domain
      t.references :tag
      t.boolean :alert_on_new_tags
      t.boolean :alert_on_removed_tags
      t.boolean :alert_on_new_tag_versions
      t.boolean :alert_on_new_tag_version_audit_completions
      t.boolean :alert_on_tagsafe_score_exceeded_thresholds
      t.boolean :alert_on_slow_tag_response_times
      t.float :tagsafe_score_threshold
      t.float :tagsafe_score_percent_drop_threshold
      t.float :tag_slow_response_time_ms_threshold
      t.float :tag_slow_response_time_percent_increase_threshold
      t.integer :num_slow_responses_before_alert
    end

    create_table :triggered_alerts do |t|
      t.string :uid, index: true
      t.string :type
      t.references :tag
      t.references :initiating_record, polymorphic: true
      t.text :triggered_reason_text
      t.timestamps
    end

    create_table :triggered_alert_domain_users do |t|
      t.string :uid, index: true
      t.references :triggered_alert
      t.references :domain_user
    end

    rename_column :audits, :initiated_by_user_id, :initiated_by_domain_user_id
  end

  def down
    drop_table :alert_configurations
    drop_table :triggered_alerts
    drop_table :triggered_alert_domain_users
  end
end
