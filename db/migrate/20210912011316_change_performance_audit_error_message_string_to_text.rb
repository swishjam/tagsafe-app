class ChangePerformanceAuditErrorMessageStringToText < ActiveRecord::Migration[6.1]
  def change
    change_column :performance_audits, :error_message, :text
  end
end
