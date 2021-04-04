class RemoveTagsLogic < ActiveRecord::Migration[5.2]
  def change
    drop_table :scripts
    
    rename_table :tags, :tags
    rename_table :script_images, :tag_images
    rename_table :tag_versions, :tag_versions
    rename_table :script_checks, :tag_checks
    rename_table :script_image_domain_lookup_patterns, :tag_image_domain_lookup_patterns
    rename_table :tag_allowed_performance_audit_third_party_urls, :tag_allowed_performance_audit_third_party_urls
    rename_table :script_check_region, :tag_check_region

    remove_column :tags, :script_id
    remove_index :tags, name: :index_tags_on_script_id
    add_column :tags, :full_url, :text
    add_column :tags, :url_domain, :string
    add_column :tags, :url_path, :string
    add_column :tags, :url_query_param, :text
    add_column :tags, :should_log_tag_checks, :boolean
    add_column :tags, :content_changed_at, :timestamp
    add_reference :tags, :tag_image
    remove_column :tags, :first_tag_version_id
    remove_column :tags, :tag_version_retention_count
    remove_column :tags, :script_check_retention_count
    remove_column :tags, :active
    rename_column :tags, :allowed_third_party_tag, :is_allowed_third_party_tag

    add_column :organizations, :tag_version_retention_count, :integer
    add_column :organizations, :tag_check_retention_count, :integer

    remove_column :tag_versions, :script_id
    add_reference :tag_versions, :tag

    remove_column :audits, :tag_version_id
    add_reference :audits, :tag_version
    remove_column :audits, :tag_id
    add_reference :audits, :tag

    remove_column :tag_checks, :script_id
    add_reference :tag_checks, :tag

    remove_column :email_notification_subscribers, :tag_id
    add_reference :email_notification_subscribers, :tag

    remove_column :performance_audit_preferences, :tag_id
    add_reference :performance_audit_preferences, :tag

    remove_column :slack_notification_subscribers, :tag_id
    add_reference :slack_notification_subscribers, :tag
    
    remove_column :tag_allowed_performance_audit_third_party_urls, :tag_id
    add_reference :tag_allowed_performance_audit_third_party_urls, :tag

    remove_column :tag_image_domain_lookup_patterns, :script_image_id
    add_reference :tag_image_domain_lookup_patterns, :tag

    remove_column :tag_checks, :script_check_region_id
    add_reference :tag_checks, :tag_check_region

    drop_table :tag_lint_results
    drop_table :lint_results
    drop_table :lint_rules
    drop_table :script_test_types
    drop_table :test_runs
    drop_table :organization_lint_rules
    remove_column :organizations, :maximum_active_tags
  end
end
