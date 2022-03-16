module LambdaEventResponses
  class HtmlSnapshotResult < Base
    def process_results!
      if html_s3_url
        html_snapshot.update!(html_s3_location: html_s3_url, screenshot_s3_location: screenshot_s3_url, completed_at: Time.now)
        return unless page_change_audit_completed_successfully?
        PageChangeAuditResultsAnalyzer.new(page_change_audit).analyze_results!
        page_change_audit.completed!
      else
        # TODO: allow HtmlSnapshot errors and retries
        page_change_audit.failed!("An unexpected error occurred: #{error}.")
      end
    end

    def html_snapshot
      @html_snapshot ||= HtmlSnapshot.find(request_payload['html_snapshot_id'])
    end
    alias record html_snapshot

    private

    def page_change_audit_completed_successfully?
      return false if page_change_audit.failed?
      page_change_audit.html_snapshots_without_tag.completed.count == 2 && page_change_audit.html_snapshot_with_tag&.completed?
    end

    def page_change_audit
      @page_change_audit ||= html_snapshot.page_change_audit
    end

    def html_s3_url
      @html_s3_url ||= response_payload['html_s3_url']
    end

    def screenshot_s3_url
      @screenshot_s3_url ||= response_payload['screenshot_s3_url']
    end

    def error
      @error ||= response_payload['errorMessage'] || response_payload['error']
    end
  end
end