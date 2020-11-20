class UpdateTestResultsColumnType < ActiveRecord::Migration[5.2]
  def change
    change_column :test_results, :result, :text
  end
end
