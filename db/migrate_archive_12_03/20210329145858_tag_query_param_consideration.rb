class TagQueryParamConsideration < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :consider_query_param_changes_new_tag, :boolean
    rename_column :scripts, :url, :full_url
    add_column :scripts, :url_domain, :string
    add_column :scripts, :url_path, :string
    add_column :scripts, :url_query_param, :text

    add_index :scripts, :url_domain
    add_index :scripts, :url_path
  end
end
