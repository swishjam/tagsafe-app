class ChangeTagEventToGenericPolymorphic < ActiveRecord::Migration[6.1]
  def change
    rename_table :tag_events, :events
    
    remove_column :events, :tag_id
    remove_column :events, :url_crawl_id
    
    add_reference :events, :triggerer
    add_column :events, :triggerer_type, :string 
  end
end
