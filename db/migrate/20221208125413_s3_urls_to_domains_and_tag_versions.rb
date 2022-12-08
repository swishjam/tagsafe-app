class S3UrlsToDomainsAndTagVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :domains, :instrumentation_s3_url, :string
    add_column :tag_versions, :js_content_s3_url, :string
  end
end
