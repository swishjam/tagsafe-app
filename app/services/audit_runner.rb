class AuditRunner
  def initialize(audit:, tag_version:, url_to_audit_id:, execution_reason:, options: {})
    @tag_version = tag_version
    @url_to_audit_id = url_to_audit_id
    @tag = @tag_version.tag
    @execution_reason = execution_reason
    # @options = options
    
    @include_performance_audit = options[:include_performance_audit] != nil ? options[:include_performance_audit] : true
    @include_page_load_resources = options[:include_page_load_resources] != nil ? options[:include_page_load_resources] : true
    @include_page_change_audit = options[:include_page_change_audit] != nil ? options[:include_page_change_audit] : true
    @include_functional_tests = options[:include_functional_tests] != nil ? options[:include_functional_tests] : true
    
    @num_performance_audits_by_type_to_enqueue_simulataneously = 1

    @audit = audit || create_audit
  end

  def run!
    audit.update(enqueued_suite_at: DateTime.now)
    enqueue_performance_audit!
    enqueue_functional_tests!
    enqueue_page_change_audit!
    audit
  end

  private

  def enqueue_performance_audit!
    if @include_performance_audit
      @num_performance_audits_by_type_to_enqueue_simulataneously.times do
        audit.enqueue_next_individual_performance_audit_if_necessary!(:with_tag)
        audit.enqueue_next_individual_performance_audit_if_necessary!(:without_tag)
      end
    end
  end

  def enqueue_page_change_audit!
    if @include_page_change_audit
      AuditRunnerJobs::RunPageChangeAudit.perform_later(audit)
    end
  end

  def enqueue_functional_tests!
    if @include_functional_tests
      AuditRunnerJobs::RunFunctionalTestSuiteForAudit.perform_later(audit)
    end
  end

  def audit
    @audit ||= Audit.create!(
      tag: @tag,
      tag_version: @tag_version,
      page_url: url_to_audit.page_url,
      execution_reason: @execution_reason,
      primary: false,
      performance_audit_calculator: @tag.domain.current_performance_audit_calculator,
      performance_audit_iterations: tag_preferences.performance_audit_iterations,
      include_performance_audit: @include_performance_audit,
      include_page_load_resources: @include_page_load_resources,
      include_page_change_audit: @include_page_change_audit,
      include_functional_tests: @include_functional_tests,
      num_functional_tests_to_run: @include_functional_tests ? @tag.functional_tests.enabled.count : 0
    )
  end
  alias create_audit audit
  
  def tag_preferences
    @tag_preferences ||= @tag.tag_preferences
  end

  def url_to_audit
    @url_to_audit ||= UrlToAudit.find(@url_to_audit_id)
  end
end
