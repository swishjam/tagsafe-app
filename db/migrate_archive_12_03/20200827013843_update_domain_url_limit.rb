class UpdateDomainUrlLimit < ActiveRecord::Migration[5.2]
  def change
    # change_column :domains, :url, :string
    # add_index :domains, :url

    remove_index :scripts, name: :index_scripts_on_url
    change_column :scripts, :url, :text
  end
end
