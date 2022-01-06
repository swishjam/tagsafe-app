module AuditRunnerJobs
  class RunPageChangeAudit < ApplicationJob
    def perform(audit)
      run_full_page_change_audit!(audit)
    # rescue HtmlSnapshotError::SnapshotFailed => e
    #   run_full_page_change_audit!(audit)
    end

    def run_full_page_change_audit!(audit)
      page_change_audit = PageChangeAudit.create(audit: audit)
      run_html_snapshotter_for(page_change_audit, HtmlSnapshotWithoutTag)
      run_html_snapshotter_for(page_change_audit, HtmlSnapshotWithoutTag)
      run_html_snapshotter_for(page_change_audit, HtmlSnapshotWithTag)
      PageChangeAuditResultsAnalyzer.new(page_change_audit).analyze_results!
      audit.page_change_audit_completed!
    end

    def run_html_snapshotter_for(page_change_audit, html_snapshot_klass)
      snapshotter = LambdaModerator::HtmlSnapshotter.new(page_change_audit: page_change_audit, html_snapshot_klass: html_snapshot_klass)
      resp = snapshotter.send!
      if resp.successful && resp.response_body['html_s3_url']
        snapshotter.html_snapshot.update!(html_s3_location: resp.response_body['html_s3_url'], screenshot_s3_location: resp.response_body['screenshot_s3_url'])
      else
        raise HtmlSnapshotError::SnapshotFailed, "`HtmlSnapshotter` lambda sender failed: #{resp['errorMessage'] || resp['error']}"
      end
    end
  end
end