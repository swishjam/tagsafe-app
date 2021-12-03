class CreateChartDataTable < ActiveRecord::Migration[5.2]
  def change
    create_table :chart_datas do |t|
      t.datetime :timestamp
      t.integer :audit_id
      t.boolean :due_to_tag_version
    end
  end
end
