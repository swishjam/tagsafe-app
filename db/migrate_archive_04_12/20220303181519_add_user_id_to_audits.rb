class AddUserIdToAudits < ActiveRecord::Migration[6.1]
  def up
    add_reference :audits, :initiated_by_domain_user
  end
end
