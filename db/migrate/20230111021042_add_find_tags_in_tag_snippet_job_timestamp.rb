class AddFindTagsInTagSnippetJobTimestamp < ActiveRecord::Migration[6.1]
  def change
    add_column :tag_snippets, :created_at, :timestamp
    add_column :tag_snippets, :updated_at, :timestamp
    add_column :tag_snippets, :find_tags_injected_by_snippet_job_enqueued_at, :timestamp
    add_column :tag_snippets, :find_tags_injected_by_snippet_job_completed_at, :timestamp
  end
end
