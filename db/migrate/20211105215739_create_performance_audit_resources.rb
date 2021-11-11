class CreatePerformanceAuditResources < ActiveRecord::Migration[6.1]
  def change
    # create_table :page_load_resources do |t|
    #   t.references :performance_audit
    #   t.string :uid
    #   t.text :name
    #   t.string :entry_type
    #   t.string :initiator_type
    #   t.float :fetch_start
    #   t.float :response_end
    #   t.float :duration
    # end
    add_column :page_load_resources, :initiator_type, :string
  end
end
