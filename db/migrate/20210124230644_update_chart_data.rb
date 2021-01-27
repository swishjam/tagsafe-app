class UpdateChartData < ActiveRecord::Migration[5.2]
  def change
    rename_table :chart_data, :script_subscriber_audits_chart_data
    add_column :script_subscriber_audits_chart_data, :script_subscriber_id, :integer
    add_column :script_subscriber_audits_chart_data, :script_change_id, :integer
    add_column :script_subscriber_audits_chart_data, :task_duration, :float
    add_column :script_subscriber_audits_chart_data, :dom_complete, :float
    add_column :script_subscriber_audits_chart_data, :dom_interactive, :float
    add_column :script_subscriber_audits_chart_data, :first_contentful_paint, :float
    add_column :script_subscriber_audits_chart_data, :script_duration, :float
    add_column :script_subscriber_audits_chart_data, :layout_duration, :float
    add_column :script_subscriber_audits_chart_data, :tagsafe_score, :float
    remove_column :script_subscriber_audits_chart_data, :due_to_script_change
    remove_column :script_subscriber_audits_chart_data, :audit_id
  end
end
