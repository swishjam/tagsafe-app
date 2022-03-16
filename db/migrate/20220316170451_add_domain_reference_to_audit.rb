class AddDomainReferenceToAudit < ActiveRecord::Migration[6.1]
  def up
    add_reference :audits, :domain
  end

  def down
    remove_column :audits, :domain_id
  end
end
