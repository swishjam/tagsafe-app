module AuditRunnerJobs
  class RunPageChangeAudit < ApplicationJob
    queue_as TagsafeQueue.CRITICAL
    
    def perform(audit, options = {})
      page_change_audit = PageChangeAudit.create(audit: audit)
      run_html_snapshotter_for(page_change_audit, HtmlSnapshotWithoutTag)
      run_html_snapshotter_for(page_change_audit, HtmlSnapshotWithoutTag)
      run_html_snapshotter_for(page_change_audit, HtmlSnapshotWithTag)
    end

    def run_html_snapshotter_for(page_change_audit, html_snapshot_klass)
      LambdaFunctionInvoker::HtmlSnapshotter.new(page_change_audit: page_change_audit, html_snapshot_klass: html_snapshot_klass).send!
    end
  end
end