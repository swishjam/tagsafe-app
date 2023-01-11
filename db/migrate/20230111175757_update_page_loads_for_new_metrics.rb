class UpdatePageLoadsForNewMetrics < ActiveRecord::Migration[6.1]
  def change
    add_column :page_loads, :num_tagsafe_injected_tags, :integer
    add_column :page_loads, :num_tagsafe_hosted_tags, :integer
    add_column :page_loads, :num_tags_not_hosted_by_tagsafe, :integer
    add_column :page_loads, :num_tags_with_tagsafe_overridden_load_strategies, :integer
  end
end
