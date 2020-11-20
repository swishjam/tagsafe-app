class AddLighthouseErrors < ActiveRecord::Migration[5.2]
  def change
    add_column :lighthouse_audits, :error_message, :mediumtext
  end
end
