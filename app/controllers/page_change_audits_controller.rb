class PageChangeAuditsController < ApplicationController
  def show
    tag = current_domain.tags.find(params[:tag_id])
    tag_version = tag.tag_versions.find(params[:tag_version_id])
    audit = tag_version.audits.find(params[:audit_id])
    page_change_audit = audit.page_change_audit
    diff_analyzer = DiffAnalyzer.new(
      new_content: page_change_audit.html_snapshot_with_tag.fetch_html_content,
      previous_content: page_change_audit.html_snapshot_without_tag.fetch_html_content,
      num_lines_of_context: 5
    )
    render turbo_stream: turbo_stream.replace(
      "audit_#{audit.uid}_page_change_audit",
      partial: 'page_change_audits/show',
      locals: {
        tag: tag,
        tag_version: tag_version,
        audit: audit,
        page_change_audit: page_change_audit,
        additions_html: page_change_audit.absolute_changes > 0 ? diff_analyzer.html_split_diff_additions : '',
        deletions_html: page_change_audit.absolute_changes > 0 ? diff_analyzer.html_split_diff_deletions : '',
        additions_count: page_change_audit.absolute_additions,
        deletions_count: page_change_audit.absolute_deletions
      }
    )
  end
end