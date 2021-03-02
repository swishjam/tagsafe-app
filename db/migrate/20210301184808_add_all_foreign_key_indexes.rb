class AddAllForeignKeyIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :audits, :script_change_id
    add_index :audits, :script_subscriber_id
    add_index :audits, :execution_reason_id
    add_index :domain_scans, :domain_id
    add_index :email_notification_subscribers, :user_id
    add_index :email_notification_subscribers, :script_subscriber_id
    add_index :lint_results, :script_change_id
    add_index :organization_lint_rules, :lint_rule_id
    add_index :organization_lint_rules, :organization_id
    add_index :organization_users, :user_id
    add_index :organization_users, :organization_id
    add_index :performance_audit_preferences, :script_subscriber_id
    add_index :performance_audits, :audit_id
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    add_index :script_checks, :script_id
    add_index :script_image_domain_lookup_patterns, :script_image_id
    add_index :script_subscriber_allowed_performance_audit_tags, :script_subscriber_id, name: 'index_allowed_performance_audit_tags_on_script_subscriber_id'
    add_index :script_subscriber_lint_results, :script_subscriber_id
    add_index :script_subscriber_lint_results, :lint_result_id
    add_index :scripts, :script_image_id
    add_index :slack_notification_subscribers, :script_subscriber_id
    add_index :slack_settings, :organization_id
    add_index :user_invites, :organization_id
    add_index :user_invites, :invited_by_user_id
  end
end