class AddPageLoadTraceToPerformanceAudit < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_audits, :page_trace_s3_url, :string
  end
end
