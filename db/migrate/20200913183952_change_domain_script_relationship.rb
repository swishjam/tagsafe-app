class ChangeDomainTagRelationship < ActiveRecord::Migration[5.2]
  def change
    # drop_table :domains_scripts
    create_table :tags do |t|
      t.references :domain
      t.references :script
      t.boolean :live
    end
  end
end
