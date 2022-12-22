class AddInterceptDataAndLoadTypeToTags < ActiveRecord::Migration[6.1]
  def change
    # add_column :tags, :load_type, :string
    # add_column :tags, :is_tagsafe_js_interceptable, :boolean
    # add_column :tags, :tagsafe_js_intercepted_count, :integer
    # add_column :tags, :tagsafe_js_optimized_count, :integer
    # add_column :tags, :tagsafe_js_not_intercepted_count, :integer
    
    add_reference :audits, :execution_reason
  end
end
