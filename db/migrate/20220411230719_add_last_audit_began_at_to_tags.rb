class AddLastAuditBeganAtToTags < ActiveRecord::Migration[6.1]
  def up
    add_column :tags, :last_audit_began_at, :timestamp
  end

  def down
    remove_column :tags, :last_audit_began_at
  end
end
