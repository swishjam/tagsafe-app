class AddLongRunningTasks < ActiveRecord::Migration[6.1]
  def up
    add_column :performance_audits, :main_thread_execution_tag_responsible_for_ms, :float
    add_column :delta_performance_audits, :main_thread_execution_tag_responsible_for_ms_delta, :float

    add_column :performance_audit_calculators, :main_thread_execution_tag_responsible_for_ms_weight, :float
    add_column :performance_audit_calculators, :main_thread_execution_tag_responsible_for_ms_decrement_amount, :float
    add_column :performance_audit_calculators, :speed_index_weight, :float
    add_column :performance_audit_calculators, :speed_index_decrement_amount, :float
    add_column :performance_audit_calculators, :perceptual_speed_index_weight, :float
    add_column :performance_audit_calculators, :perceptual_speed_index_decrement_amount, :float
    add_column :performance_audit_calculators, :ms_until_first_visual_change_weight, :float
    add_column :performance_audit_calculators, :ms_until_first_visual_change_decrement_amount, :float
    add_column :performance_audit_calculators, :ms_until_last_visual_change_weight, :float
    add_column :performance_audit_calculators, :ms_until_last_visual_change_decrement_amount, :float

    create_table :long_tasks do |t|
      t.string :uid, index: true
      t.references :performance_audit
      t.references :tag
      t.references :tag_version
      t.string :task_type
      t.float :start_time
      t.float :end_time
      t.float :duration
      t.float :self_time
    end

    remove_column :performance_audit_calculators, :main_thread_execution_tag_responsible_for_ms_decrement_amount
    remove_column :performance_audit_calculators, :speed_index_decrement_amount
    remove_column :performance_audit_calculators, :perceptual_speed_index_decrement_amount
    remove_column :performance_audit_calculators, :ms_until_first_visual_change_decrement_amount
    remove_column :performance_audit_calculators, :ms_until_last_visual_change_decrement_amount

    rename_column :performance_audits, :main_thread_execution_tag_responsible_for_ms, :main_thread_execution_tag_responsible_for
    rename_column :delta_performance_audits, :main_thread_execution_tag_responsible_for_ms_delta, :main_thread_execution_tag_responsible_for_delta
    rename_column :performance_audit_calculators, :main_thread_execution_tag_responsible_for_ms_weight, :main_thread_execution_tag_responsible_for_weight

    add_column :performance_audit_calculators, :main_thread_execution_tag_responsible_for_score_decrement_amount, :float
    add_column :performance_audit_calculators, :speed_index_score_decrement_amount, :float
    add_column :performance_audit_calculators, :perceptual_speed_index_score_decrement_amount, :float
    add_column :performance_audit_calculators, :ms_until_first_visual_change_score_decrement_amount, :float
    add_column :performance_audit_calculators, :ms_until_last_visual_change_score_decrement_amount, :float
  end
end
