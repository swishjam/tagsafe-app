class MoveAwsAttributesToExecutedStepFunction < ActiveRecord::Migration[6.1]
  def change
    remove_column :performance_audits, :aws_log_stream_name
    remove_column :performance_audits, :aws_request_id
    remove_column :performance_audits, :aws_trace_id

    remove_column :url_crawls, :aws_log_stream_name
    remove_column :url_crawls, :aws_request_id
    remove_column :url_crawls, :aws_trace_id

    add_column :executed_step_functions, :aws_log_stream_name, :string
    add_column :executed_step_functions, :aws_request_id, :string
    add_column :executed_step_functions, :aws_trace_id, :string
  end
end
