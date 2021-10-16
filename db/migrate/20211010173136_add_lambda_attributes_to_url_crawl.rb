class AddLambdaAttributesToUrlCrawl < ActiveRecord::Migration[6.1]
  def change
    add_column :url_crawls, :aws_log_stream_name, :string
    add_column :url_crawls, :aws_request_id, :string
    add_column :url_crawls, :aws_trace_id, :string
  end
end
