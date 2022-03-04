class AddUserIdToAudits < ActiveRecord::Migration[6.1]
  def up
    add_reference :audits, :initiated_by_user
  end
end
