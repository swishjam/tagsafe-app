module PerformanceAuditManager
  class ValidityChecker
    attr_accessor :invalid_reason

    def initialize(audited_tag_url:, results_with_tag:, results_without_tag:)
      @audited_tag_url = audited_tag_url
      @results_with_tag = results_with_tag
      @results_without_tag = results_without_tag
    end

    def valid?
      if !blocked_tag_in_audit_without_tag
        @invalid_reason = <<-REASON
          One or more of the performance audits did not block the audited tag when it should have. 
          Check to ensure the tag is present on this page, or if it's deployed via a tag manager ensure the tag 
          manager is an allowed tag in the tag's performance audit settings. Review the audit logs for more info.
        REASON
        false
      elsif !overwrote_tag_in_audit_with_tag
        @invalid_reason = <<-REASON
          One or more of the performance audits did not allow the audited tag when it should have. 
          Check to ensure the tag is present on this page, or if it's deployed via a tag manager ensure the tag 
          manager is an allowed tag in the tag's performance audit settings. Review the audit logs for more info.
        REASON
        false
      else
        true
      end
    end

    private

    def blocked_tag_in_audit_without_tag
      @results_without_tag['blocked_tags'].map{ |blocked_array| blocked_array.include?(@audited_tag_url) }.all?(true)
    end

    def overwrote_tag_in_audit_with_tag
      @results_with_tag['overwritten_tags'].map{ |overwritten_array| overwritten_array.include?(@audited_tag_url) }.all?(true)
    end
  end
end