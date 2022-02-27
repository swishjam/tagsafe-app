class AddInitialHtmlContentS3UrlToPageChangeAudit < ActiveRecord::Migration[6.1]
  def change
    add_column :page_change_audits, :initial_html_content_s3_url, :string
  end
end
