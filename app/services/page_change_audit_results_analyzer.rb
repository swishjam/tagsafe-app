class PageChangeAuditResultsAnalyzer
  def initialize(page_change_audit)
    @page_change_audit = page_change_audit
  end

  def analyze_results!
    ensure_page_change_audit_is_complete!

    control_additions = diff_analyzer_between_without_tag_snapshots.num_additions
    control_deletions = diff_analyzer_between_without_tag_snapshots.num_deletions
    variable_additions = diff_analyzer_between_with_and_without_tag_snapshots.num_additions
    variable_deletions = diff_analyzer_between_with_and_without_tag_snapshots.num_deletions

    @page_change_audit.update!(
      num_additions_between_without_tag_snapshots: control_additions,
      num_deletions_between_without_tag_snapshots: control_additions,
      num_additions_between_with_tag_snapshot_without_tag_snapshot: variable_additions,
      num_deletions_between_with_tag_snapshot_without_tag_snapshot: variable_deletions,
      tag_causes_page_changes: control_additions != variable_additions || control_deletions != variable_deletions
    )
  end

  private

  def diff_analyzer_between_without_tag_snapshots
    return @analyzer_without_tag_snapshots if defined?(@analyzer_without_tag_snapshots)
    snapshots = @page_change_audit.html_snapshots_without_tag
    @analyzer_without_tag_snapshots  = DiffAnalyzer.new(
      new_content: snapshots.first.fetch_html_content, 
      previous_content: snapshots.last.fetch_html_content
    )
  end

  def diff_analyzer_between_with_and_without_tag_snapshots
    return @analyzer_with_and_without_tag_snapshots if defined?(@analyzer_with_and_without_tag_snapshots)
    html_without_tag = @page_change_audit.html_snapshots_without_tag.first.fetch_html_content
    html_with_tag = @page_change_audit.html_snapshot_with_tag.fetch_html_content
    @analyzer_with_and_without_tag_snapshots = DiffAnalyzer.new(new_content: html_without_tag, previous_content: html_with_tag)
  end

  def ensure_page_change_audit_is_complete!
    snapshots_without_tag = @page_change_audit.html_snapshots_without_tag.completed
    snapshot_with_tag = @page_change_audit.html_snapshot_with_tag
    completed_all_snapshots = snapshots_without_tag.count == 2 && snapshot_with_tag.completed?
    if !completed_all_snapshots
      raise StandardError, "`page_change_audit` #{@page_change_audit.uid} should have 2 completed snapshots without tag and 1 completed snapshot with tag"
    end
  end
end