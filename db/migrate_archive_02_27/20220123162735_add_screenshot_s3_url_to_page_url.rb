class AddScreenshotS3UrlToPageUrl < ActiveRecord::Migration[6.1]
  def change
    add_column :page_urls, :screenshot_s3_url, :string
  end
end
