class AddAdditionalPerformanceAuditConfigColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_audit_configurations,  :scroll_page, :boolean
    add_column :performance_audit_configurations,  :enable_screen_recording, :boolean
    add_column :performance_audit_configurations,  :override_initial_html_request_with_manipulated_page, :boolean
  end
end
