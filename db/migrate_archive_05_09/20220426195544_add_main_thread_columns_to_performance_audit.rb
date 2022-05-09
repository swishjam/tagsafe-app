class AddMainThreadColumnsToPerformanceAudit < ActiveRecord::Migration[6.1]
  def up
    add_column :performance_audits, :main_thread_blocking_execution_tag_responsible_for, :float
    add_column :performance_audits, :entire_main_thread_execution_ms, :float
    add_column :performance_audits, :entire_main_thread_blocking_executions_ms, :float

    add_column :delta_performance_audits, :main_thread_blocking_execution_tag_responsible_for_delta, :float
    add_column :delta_performance_audits, :entire_main_thread_execution_ms_delta, :float
    add_column :delta_performance_audits, :entire_main_thread_blocking_executions_ms_delta, :float
  end
end
