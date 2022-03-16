class AddReceivedResponseAtColumnsToLambdaReliantModels < ActiveRecord::Migration[6.1]
  def up
    add_column :url_crawls, :lambda_response_received_at, :datetime
    add_column :performance_audits, :lambda_response_received_at, :datetime
    add_column :test_runs, :lambda_response_received_at, :datetime
    add_column :html_snapshots, :lambda_response_received_at, :datetime
  end

  def down
    remove_column :url_crawls, :lambda_response_received_at
    remove_column :performance_audits, :lambda_response_received_at
    remove_column :test_runs, :lambda_response_received_at
    remove_column :html_snapshots, :lambda_response_received_at
  end
end
