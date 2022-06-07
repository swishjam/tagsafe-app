const performanceAuditHandler = require('./performanceAuditHandler');

(async () => {
  process.env.MOCK_S3_UPLOADS = 'true';
  process.env.S3_BUCKET_NAME = 'local-s3-bucket';
  process.env.INCLUDE_RAW_AUDIT_RESULTS_IN_RESPONSE = 'true';

  const allTagsEventData = {
    "individual_performance_audit_id": -1,
    "allow_all_third_party_tags": true,
    "page_url_to_perform_audit_on": "https://www.att.com",
    "first_party_request_url": "https://www.att.com",
    "third_party_tag_urls_and_rules_to_inject": [],
    "third_party_tag_url_patterns_to_allow": [],
    "cached_responses_s3_key": null,
    "options": {
      "override_initial_html_request_with_manipulated_page": "true",
      "puppeteer_page_timeout_ms": 0,
      "enable_screen_recording": "false",
      "throw_error_if_dom_complete_is_zero": "false",
      "include_page_load_resources": "false",
      "upload_filmstrip_frames_to_s3": "false",
      "inline_injected_script_tags": "false",
      "scroll_page": "false",
      "strip_all_images": "false",
      "strip_all_css": "false"
    },
    "lambda_invoker_klass": "StepFunctionInvoker::PerformanceAuditer",
    "executed_step_function_id": 0,
    "executed_step_function_uid": "esf_123",
    "ProcessReceivedLambdaEventJobQueue": "lambda_results"
  }

  const noTagsEventData = {
    "individual_performance_audit_id": -1,
    "allow_all_third_party_tags": false,
    "page_url_to_perform_audit_on": "https://www.att.com",
    "first_party_request_url": "https://www.att.com",
    "third_party_tag_urls_and_rules_to_inject": [],
    "third_party_tag_url_patterns_to_allow": [],
    "cached_responses_s3_key": null,
    "options": {
      "override_initial_html_request_with_manipulated_page": "true",
      "puppeteer_page_timeout_ms": 0,
      "enable_screen_recording": "false",
      "throw_error_if_dom_complete_is_zero": "false",
      "include_page_load_resources": "false",
      "upload_filmstrip_frames_to_s3": "false",
      "inline_injected_script_tags": "false",
      "scroll_page": "false",
      "strip_all_images": "false",
      "strip_all_css": "false"
    },
    "lambda_invoker_klass": "StepFunctionInvoker::PerformanceAuditer",
    "executed_step_function_id": 0,
    "executed_step_function_uid": "esf_123",
    "ProcessReceivedLambdaEventJobQueue": "lambda_results"
  }
  
  const allTagsRes = await performanceAuditHandler.runPerformanceAudit(allTagsEventData, { serverlessSdk: { tagEvent: () => {} }} );
  const noTagsRes = await performanceAuditHandler.runPerformanceAudit(noTagsEventData, { serverlessSdk: { tagEvent: () => {} }} );

  const delta = {
    DOMComplete: allTagsRes.jsonResults.results.DOMComplete - noTagsRes.jsonResults.results.DOMComplete,
    DOMInteractive: allTagsRes.jsonResults.results.DOMInteractive - noTagsRes.jsonResults.results.DOMInteractive,
    DOMContentLoaded: allTagsRes.jsonResults.results.DOMContentLoaded - noTagsRes.jsonResults.results.DOMContentLoaded,
    FirstContentfulPaint: allTagsRes.jsonResults.results.FirstContentfulPaint - noTagsRes.jsonResults.results.FirstContentfulPaint,
    SpeedIndex: allTagsRes.jsonResults.speed_index.speed_index - noTagsRes.jsonResults.speed_index.speed_index,
    AllTagsMainThreadResults: allTagsRes.jsonResults.main_thread_results,
    NoTagsMainThreadResults: noTagsRes.jsonResults.main_thread_results,
  }
  console.log(`

    ============

    DOM Complete w/ tags: ${allTagsRes.jsonResults.results.DOMComplete}
    DOM Complete w/o tags: ${noTagsRes.jsonResults.results.DOMComplete}
    DOM Complete Delta: ${allTagsRes.jsonResults.results.DOMComplete - noTagsRes.jsonResults.results.DOMComplete}
    Third Party tags increase DOM Complete %: ${((allTagsRes.jsonResults.results.DOMComplete - noTagsRes.jsonResults.results.DOMComplete) / allTagsRes.jsonResults.results.DOMComplete) * 100}%
    
    DOM Interactive w/ tags: ${allTagsRes.jsonResults.results.DOMInteractive}
    DOM Interactive w/o tags: ${noTagsRes.jsonResults.results.DOMInteractive}
    DOM Interactive Delta: ${allTagsRes.jsonResults.results.DOMInteractive - noTagsRes.jsonResults.results.DOMInteractive}
    Third Party tags increase DOM Interactive %: ${((allTagsRes.jsonResults.results.DOMInteractive - noTagsRes.jsonResults.results.DOMInteractive) / allTagsRes.jsonResults.results.DOMInteractive) * 100}%

    DOM Content Loaded w/ tags: ${allTagsRes.jsonResults.results.DOMContentLoaded}
    DOM Content Loaded w/o tags: ${noTagsRes.jsonResults.results.DOMContentLoaded}
    DOM Content Loaded Delta: ${allTagsRes.jsonResults.results.DOMContentLoaded - noTagsRes.jsonResults.results.DOMContentLoaded}
    Third Party tags increase DOM Content Loaded %: ${((allTagsRes.jsonResults.results.DOMContentLoaded - noTagsRes.jsonResults.results.DOMContentLoaded) / allTagsRes.jsonResults.results.DOMContentLoaded) * 100}%

    First Contentful Paint w/ tags: ${allTagsRes.jsonResults.results.FirstContentfulPaint}
    First Contentful Paint w/o tags: ${noTagsRes.jsonResults.results.FirstContentfulPaint}
    First Contentful Paint Delta: ${allTagsRes.jsonResults.results.FirstContentfulPaint - noTagsRes.jsonResults.results.FirstContentfulPaint}
    Third Party tags increase First Contentful Paint %: ${((allTagsRes.jsonResults.results.FirstContentfulPaint - noTagsRes.jsonResults.results.FirstContentfulPaint) / allTagsRes.jsonResults.results.FirstContentfulPaint) * 100}%

    Tags Main Thread Execution ms responsible for: ${allTagsRes.jsonResults.main_thread_results.total_main_thread_execution_ms_for_tag}
    Entire Thread Execution ms: ${allTagsRes.jsonResults.main_thread_results.entire_main_thread_executions_ms}
    % of main thread execution third party tags are responsible for: ${allTagsRes.jsonResults.main_thread_results.total_main_thread_execution_ms_for_tag / allTagsRes.jsonResults.main_thread_results.entire_main_thread_executions_ms * 100}%
    ============

  `)
  return delta;
})()