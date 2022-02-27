class AddErrorMessageToPageChangeAudit < ActiveRecord::Migration[6.1]
  def change
    add_column :page_change_audits, :error_message, :string
  end
end
