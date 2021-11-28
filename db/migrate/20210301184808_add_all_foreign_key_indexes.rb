class AddAllForeignKeyIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :audits, :tag_version_id
    add_index :audits, :tag_id
    add_index :audits, :execution_reason_id
    add_index :url_crawls, :domain_id
    add_index :email_notification_subscribers, :user_id
    add_index :email_notification_subscribers, :tag_id
    add_index :lint_results, :tag_version_id
    add_index :organization_lint_rules, :lint_rule_id
    add_index :organization_lint_rules, :organization_id
    add_index :organization_users, :user_id
    add_index :organization_users, :organization_id
    add_index :performance_audit_preferences, :tag_id
    add_index :performance_audits, :audit_id
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
    add_index :script_checks, :script_id
    add_index :tag_image_domain_lookup_patterns, :tag_image_id
    add_index :tag_allowed_performance_audit_third_party_urls, :tag_id, name: 'index_allowed_performance_audit_third_party_urls_on_tag_id'
    add_index :tag_lint_results, :tag_id
    add_index :tag_lint_results, :lint_result_id
    add_index :scripts, :tag_image_id
    add_index :slack_notification_subscribers, :tag_id
    add_index :slack_settings, :organization_id
    add_index :user_invites, :organization_id
    add_index :user_invites, :invited_by_user_id
  end
end
