class AddPrimaryAuditToTags < ActiveRecord::Migration[6.1]
  def change
    add_reference :tags, :primary_audit
  end
end
