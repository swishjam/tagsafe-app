module LambdaModerator
  class HtmlSnapshotter < Base
    lambda_service 'html-snapshotter'
    lambda_function 'takeSnapshot'

    def initialize(page_change_audit:, html_snapshot_klass:)
      @page_change_audit = page_change_audit
      @html_snapshot_klass = html_snapshot_klass
      @executed_lambda_function_parent = html_snapshot
    end

    def html_snapshot
      @html_snapshot ||= @html_snapshot_klass.create(page_change_audit: @page_change_audit)
    end

    def before_send
      @html_snapshot.update(enqueued_at: Time.now)
    end

    def after_send
      @html_snapshot.update(completed_at: Time.now)
    end

    def request_payload
      {
        url: audit.page_url.full_url,
        initial_html_content_s3_key: @page_change_audit.initial_html_content_s3_key,
        third_party_tag_urls_and_rules_to_inject: script_injection_rules,
        third_party_tag_url_patterns_to_allow: allowed_request_urls
      }
    end

    def script_injection_rules
      case @html_snapshot_klass.to_s
      when 'HtmlSnapshotWithTag'
        [{ 
          url:  audit.tag_version.js_file_url, 
          load_type: 'async' 
        }]
      when 'HtmlSnapshotWithoutTag'
        []
      else
        raise StandardError, "Invalid `html_snapshot_klass` passed to HtmlSnapshotter: #{@html_snapshot_klass.to_s}"
      end
    end

    def allowed_request_urls
      audit.tag.domain.non_third_party_url_patterns.collect(&:pattern)
    end

    def audit
      @audit ||= @page_change_audit.audit
    end
  end
end