class AddsParanoidColumns < ActiveRecord::Migration[6.1]
  def change
    %i[
      users
      urls_to_crawl
      url_crawls
      tags
      tag_versions
      tag_preferences
      organizations
      domains
      audits
      tag_events
      performance_audits
    ].each do |table|
      add_column table, :deleted_at, :datetime
    end
  end
end
