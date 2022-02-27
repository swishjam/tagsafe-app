class CreateIndividualAuditsDeltaAudit < ActiveRecord::Migration[6.1]
  def up
    create_table :delta_performance_audits do |t|
      t.string :uid, index: true
      t.string :type
      t.references :audit
      t.references :performance_audit_with_tag, index: { name: :index_dpa_performance_audit_with_tag_id }
      t.references :performance_audit_without_tag, index: { name: :index_dpa_performance_audit_without_tag_id }
      t.float :dom_complete_delta
      t.float :dom_content_loaded_delta
      t.float :dom_interactive_delta
      t.float :first_contentful_paint_delta
      t.float :script_duration_delta
      t.float :layout_duration_delta
      t.float :task_duration_delta
      t.float :tagsafe_score
      t.timestamps
    end

    remove_column :performance_audits, :tagsafe_score
    remove_column :performance_audits, :tagsafe_score_standard_deviation
    remove_column :performance_audits, :enqueued_at
    remove_column :performance_audits, :used_for_scoring
    add_column :performance_audits, :audit_performed_with_tag, :boolean
  end

  def down
  end
end
