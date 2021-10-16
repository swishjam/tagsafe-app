class AddAwsIdentifiersToIndividualPerformanceAudits < ActiveRecord::Migration[6.1]
  def change
    add_column :performance_audits, :aws_log_stream_name, :string
    add_column :performance_audits, :aws_request_id, :string
    add_column :performance_audits, :aws_trace_id, :string
  end
end
