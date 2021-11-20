class AddDomContentLoadedToPerformanceAudit < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_audits, :dom_content_loaded, :float
  end
end
