class ChangeTablesToReferencePageUrls < ActiveRecord::Migration[6.1]
  def change
    # add_column :page_urls, :should_scan_for_tags, :boolean
    # add_reference :urls_to_audit, :page_url, index: true
    # add_reference :url_crawls, :page_url, index: true
    # add_reference :tags, :found_on_page_url, index: true

    add_reference :urls_to_audit, :page_url, index: true
    remove_column :page_urls, :should_run_audits_on
  end
end