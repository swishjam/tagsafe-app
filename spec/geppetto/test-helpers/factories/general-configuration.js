const Factory = require('./factory'),
      DBConnecter = require('../dbConnecter');

module.exports = class GeneralConfiguration extends Factory {
  constructor(attrs) {
    super();
    this.parentId = attrs['parentId'];
    this.parentType = attrs['parentType'];
    this.includePerformanceAudit = Factory._attrOrDefault(attrs['includePerformanceAudit'], true);
    this.includePageLoadResources = Factory._attrOrDefault(attrs['includePageLoadResources'], true);
    this.includePageChangeAudit = Factory._attrOrDefault(attrs['includePageChangeAudit'], false);
    this.includeFunctionalTests = Factory._attrOrDefault(attrs['includeFunctionalTests'], true);
    this.numFunctionalTestsToRun = Factory._attrOrDefault(attrs['numFunctionalTestsToRun'], 0);
    this.numPerfAuditsToRun = Factory._attrOrDefault(attrs['numPerfAuditsToRun'], 10);
    this.perfAuditStripAllImages = Factory._attrOrDefault(attrs['perfAuditStripAllImages'], false);
    this.perfAuditIncludePageTracing = Factory._attrOrDefault(attrs['perfAuditIncludePageTracing'], true);
    this.perfAuditThrowErrorIfDomCompleteIsZero = Factory._attrOrDefault(attrs['perfAuditThrowErrorIfDomCompleteIsZero'], false);
    this.perfAuditInlineInjectedScriptTags = Factory._attrOrDefault(attrs['perfAuditInlineInjectedScriptTags'], false);
    this.perfAuditScrollPage = Factory._attrOrDefault(attrs['perfAuditScrollPage'], false);
    this.perfAuditEnableScreenRecording = Factory._attrOrDefault(attrs['perfAuditEnableScreenRecording'], true);
    this.perfAuditOverrideInitialHtmlRequestWithManipulatedPage = Factory._attrOrDefault(attrs['perfAuditOverrideInitialHtmlRequestWithManipulatedPage'], true);
    this.perfAuditCompletionIndicatorType = Factory._attrOrDefault(attrs['perfAuditCompletionIndicatorType'], 'confidence');
    this.perfAuditRequiredTagsafeScoreRange = Factory._attrOrDefault(attrs['perfAuditRequiredTagsafeScoreRange'], 5.0);
    this.enableMonitoringOnNewTags = Factory._attrOrDefault(attrs['enableMonitoringOnNewTags'], false);
    this.perfAuditMinimumNumSets = Factory._attrOrDefault(attrs['perfAuditMinimumNumSets'], 3);
    this.perfAuditMaximumNumSets = Factory._attrOrDefault(attrs['perfAuditMaximumNumSets'], 20);
    this.perfAuditFailWhenConfidenceRangeNotMet = Factory._attrOrDefault(attrs['perfAuditFailWhenConfidenceRangeNotMet'], false);
    this.perfAuditBatchSize = Factory._attrOrDefault(attrs['perfAuditBatchSize'], 3);
    this.perfAuditMaxFailures = Factory._attrOrDefault(attrs['perfAuditMaxFailures'], 6);
    this.rollUpAuditsByTagVersion = Factory._attrOrDefault(attrs['rollUpAuditsByTagVersion'], false);
    this.numRecentTagVersionsToCompareInReleaseMonitoring = Factory._attrOrDefault(attrs['numRecentTagVersionsToCompareInReleaseMonitoring'], 5);
  }

  async createNewRecord() {
    const res = await DBConnecter.query(`
      INSERT INTO general_configurations(
        parent_id,
        parent_type,
        include_performance_audit,
        include_page_load_resources,
        include_page_change_audit,
        include_functional_tests,
        num_functional_tests_to_run,
        num_perf_audits_to_run,
        perf_audit_strip_all_images,
        perf_audit_include_page_tracing,
        perf_audit_throw_error_if_dom_complete_is_zero,
        perf_audit_inline_injected_script_tags,
        perf_audit_scroll_page,
        perf_audit_enable_screen_recording,
        perf_audit_override_initial_html_request_with_manipulated_page,
        perf_audit_completion_indicator_type,
        perf_audit_required_tagsafe_score_range,
        enable_monitoring_on_new_tags,
        perf_audit_minimum_num_sets,
        perf_audit_maximum_num_sets,
        perf_audit_fail_when_confidence_range_not_met,
        perf_audit_batch_size,
        perf_audit_max_failures,
        roll_up_audits_by_tag_version,
        num_recent_tag_versions_to_compare_in_release_monitoring
      )
      VALUES (
        ${this.parentId},
        '${this.parentType}',
        ${this.includePerformanceAudit},
        ${this.includePageLoadResources},
        ${this.includePageChangeAudit},
        ${this.includeFunctionalTests},
        ${this.numFunctionalTestsToRun},
        ${this.numPerfAuditsToRun},
        ${this.perfAuditStripAllImages},
        ${this.perfAuditIncludePageTracing},
        ${this.perfAuditThrowErrorIfDomCompleteIsZero},
        ${this.perfAuditInlineInjectedScriptTags},
        ${this.perfAuditScrollPage},
        ${this.perfAuditEnableScreenRecording},
        ${this.perfAuditOverrideInitialHtmlRequestWithManipulatedPage},
        '${this.perfAuditCompletionIndicatorType}',
        ${this.perfAuditRequiredTagsafeScoreRange},
        ${this.enableMonitoringOnNewTags},
        ${this.perfAuditMinimumNumSets},
        ${this.perfAuditMaximumNumSets},
        ${this.perfAuditFailWhenConfidenceRangeNotMet},
        ${this.perfAuditBatchSize},
        ${this.perfAuditMaxFailures},
        ${this.rollUpAuditsByTagVersion},
        ${this.numRecentTagVersionsToCompareInReleaseMonitoring}
      )
    `)
    return this.id = res.insertId;
  }
}