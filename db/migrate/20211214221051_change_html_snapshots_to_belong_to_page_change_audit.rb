class ChangeHtmlSnapshotsToBelongToPageChangeAudit < ActiveRecord::Migration[6.1]
  def up
    create_table :page_change_audits do |t|
      t.string :uid, index: true
      t.references :audit
      t.boolean :tag_causes_page_changes
      t.integer :num_additions_between_without_tag_snapshots
      t.integer :num_deletions_between_without_tag_snapshots
      t.integer :num_additions_between_with_tag_snapshot_without_tag_snapshot
      t.integer :num_deletions_between_with_tag_snapshot_without_tag_snapshot
    end

    remove_column :html_snapshots, :audit_id
    add_reference :html_snapshots, :page_change_audit
  end

  def down
    remove_column :html_snapshots, :page_change_audit_id
    add_reference :html_snapshots, :audit
    drop_table :page_change_audits
  end
end
