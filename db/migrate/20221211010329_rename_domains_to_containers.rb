class RenameDomainsToContainers < ActiveRecord::Migration[6.1]
  def change
    rename_table :domains, :containers
    rename_column :containers, :url, :name
    remove_column :containers, :is_generating_third_party_impact_trial
    remove_column :containers, :stripe_customer_id
    remove_column :containers, :stripe_payment_method_id
    remove_column :containers, :current_subscription_plan_id

    rename_table :domain_users, :container_users
    rename_table :alert_configuration_domain_users, :alert_configuration_container_users
    rename_table :domain_users_roles, :container_users_roles

    rename_column :alert_configuration_container_users, :domain_user_id, :container_user_id
    rename_column :alert_configurations, :domain_user_id, :container_user_id

    rename_column :audits, :domain_id, :container_id
    rename_column :container_users, :domain_id, :container_id
    rename_column :container_users_roles, :domain_id, :container_id
    rename_column :functional_tests, :domain_id, :container_id
    rename_column :instrumentation_builds, :domain_id, :container_id
    rename_column :non_third_party_url_patterns, :domain_id, :container_id
    rename_column :page_urls, :domain_id, :container_id
    rename_column :performance_audit_calculators, :domain_id, :container_id
    rename_column :tag_url_patterns_to_not_capture, :domain_id, :container_id
    rename_column :tags, :domain_id, :container_id
    rename_column :tagsafe_js_events_batches, :domain_id, :container_id
    rename_column :user_invites, :domain_id, :container_id

    # some extras while we're here...
    rename_column :tags, :url_domain, :url_hostname # UPDATE URL_DOMAINS EVERYWHERE TOO!
    remove_column :performance_audits, :domain_audit_id
    remove_column :delta_performance_audits, :domain_audit_id
  end
end
