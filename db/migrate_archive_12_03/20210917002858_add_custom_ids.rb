class AddCustomIds < ActiveRecord::Migration[6.1]
  def update_table(table_name)
    remove_column table_name, :id if column_exists?(table_name, :id)
    add_column table_name, :id, :primary_key, first: true, null: false unless column_exists?(table_name, :id)
    add_column table_name, :uid, :string, after: :id, null: false unless column_exists?(table_name, :uid)
    add_index table_name, :uid unless index_exists?(table_name, :uid)
  end

  def update_foriegn_keys_of_model(model)
    model.columns.each do |column|
      if column.name.ends_with? '_id'
        change_column model.table_name, column.name, :integer
      end
    end
  end

  def change
    Dir["app/models/*.rb"].map do |file_path|
      require Rails.root.join(file_path)
    
      basename  = File.basename(file_path, File.extname(file_path))
      klass     = basename.camelize.constantize

      puts basename
      next if ['Notifier', 'ContextualUid', 'ApplicationRecord', 'UptimeRegion'].include?(klass.to_s)
      table_name = klass.table_name
      update_table(table_name)
      update_foriegn_keys_of_model(klass)
    end

    update_table(:performance_audits)
    update_foriegn_keys_of_model(PerformanceAudit)

    update_table(:email_notification_subscribers)
    update_foriegn_keys_of_model(EmailNotificationSubscriber)

    update_table(:performance_audit_logs)
    update_foriegn_keys_of_model(PerformanceAuditLog)

    update_table(:roles_users)
    change_column :roles_users, :user_id, :integer
    change_column :roles_users, :role_id, :integer
    
    change_column :active_storage_attachments, :record_id, :integer
  end
end
