class AddDomainRelationToTestResults < ActiveRecord::Migration[5.2]
  def change
    add_column :test_results, :domain_id, :integer
  end
end
