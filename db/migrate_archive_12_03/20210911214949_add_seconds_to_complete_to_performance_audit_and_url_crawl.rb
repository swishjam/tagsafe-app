class AddSecondsToCompleteToPerformanceAuditAndUrlCrawl < ActiveRecord::Migration[6.1]
  def change
    rename_column :audits, :seconds_to_complete_performance_audit, :seconds_to_complete
    add_column :performance_audits, :seconds_to_complete, :float
    add_column :url_crawls, :seconds_to_complete, :float
  end
end
