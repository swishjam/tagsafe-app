class DropChartDataTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :script_subscriber_audits_chart_data
  end
end
