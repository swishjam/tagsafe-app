class PurgeLegacyData < ActiveRecord::Migration[6.1]
  def change
    drop_table :additional_tags_to_inject_during_audit
    drop_table :bulk_debits
    drop_table :credit_wallet_notifications
    drop_table :credit_wallet_transactions
    drop_table :credit_wallets
                drop_table :domain_audits
    drop_table :feature_prices_in_credits
    drop_table :flags
    drop_table :html_snapshots
    drop_table :js_script_configurations
    drop_table :js_scripts
    drop_table :long_tasks
    drop_table :object_flags
    drop_table :page_change_audits
    drop_table :slack_notification_subscribers
    drop_table :slack_settings
    drop_table :subscription_features_configurations
    drop_table :subscription_plans
    drop_table :subscription_usage_record_updates
    drop_table :tag_allowed_performance_audit_third_party_urls
    drop_table :tag_configurations
    drop_table :tag_inject_page_url_rules
    drop_table :url_crawl_retrieved_urls
    drop_table :url_crawls
    drop_table :urls_to_crawl

    remove_column :tags, :js_script_id
    remove_column :audits, :js_script_id
    add_reference :audits, :tag
  end
end
