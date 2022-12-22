'use strict';

const AuditRunner = require('./src/auditRunner'),
        CacheRetriever = require('./src/cacher/retriever'),
        ErrorKeeper = require('./src/errorKeeper'),
        EventConfig = require('./src/eventConfig'),
        ImageScrubber = require('./src/scrubbers/imageScrubber'),
        MainThreadAnalyzer = require('./src/traceEvaluators/mainThreadAnalyzer'),
        MonkeyPatcher = require('./src/pageManipulators/monkeyPatcher'),
        PageEventHandler = require('./src/pageEventHandler'),
        PageManipulator = require('./src/pageManipulators/pageManipulator'),
        PerformanceMetricsHandler = require('./src/performanceMetricsHandler'),
        PuppeteerModerator = require('./src/puppeteerModerator'),
        RequestInterceptor = require('./src/requestInterceptor'),
        ResourceKeeper = require('./src/resourceKeeper'),
        ScreenRecorder = require('./src/screenRecorder'),
        SpeedIndexComposer = require('./src/traceEvaluators/speedIndexComposer'),
        TagInjector = require('./src/pageManipulators/tagInjector'),
        ThirdPartyTagDetector = require('./src/thirdPartyTagDetector'),
        ThirdPartyTagScrubber = require('./src/scrubbers/thirdPartyTagScrubber'),
        Tracer = require('./src/traceEvaluators/tracer'),
        ValidityChecker = require('./src/validityChecker'),
        { uploadToS3 } = require('./src/s3');
        // { ddSendDistributionMetricWithDate } = require('datadog-lambda-js'),
        // ddTracer = require('dd-trace');

require('dotenv').config();

const runPerformanceAudit = async (event, context) => {
  const startTime = Date.now();
  let successful = true;
  let error = null;
  const { 
    allowAllThirdPartyTags,
    cachedResponsesS3Key,
    enableScreenRecording,
    firstPartyRequestUrl,
    includePageLoadResources,
    inlineInjectedScriptTags,
    navigationTimeoutMs,
    navigationWaitUntil,
    pageUrlToPerformAuditOn,
    scrollPage,
    overrideInitialHTMLRequestWithManipulatedPage,
    returnCachedResponsesImmediately,
    stripAllImages,
    thirdPartyTagUrlPatternsToNeverAllow,
    thirdPartyTagUrlsAndRulesToInject,
    thirdPartyTagUrlPatternsToAllow,
    throwErrorIfDOMCompleteIsZero,
    uploadFilmstripFramesToS3,
    userAgent
    // stripAllCSS,
    // stripAllJS
  } = new EventConfig(event).constructPerformanceAuditConfig();

  // ddSendDistributionMetricWithDate('executed-lamabda-function-uid', event.executed_step_function_uid);
  // ddSendDistributionMetricWithDate('audited-page-url', pageUrlToPerformAuditOn);
  context.serverlessSdk.tagEvent('executed-lamabda-function-uid', event.executed_step_function_uid)
  context.serverlessSdk.tagEvent('audited-page-url', pageUrlToPerformAuditOn);
  context.serverlessSdk.tagEvent('injected-urls', thirdPartyTagUrlsAndRulesToInject.length > 0 ? thirdPartyTagUrlsAndRulesToInject[0].url : 'none');
  context.serverlessSdk.tagEvent('enable-screen-recording', enableScreenRecording);

  // const logger = new Logger();
  const uniqueFilename = `${pageUrlToPerformAuditOn.replace(/\/|\:|\\|\./g, '_')}-${Date.now()}`;

  const puppeteerModerator = new PuppeteerModerator()
  const page = await puppeteerModerator.launch();

  const pageEventHandler = new PageEventHandler(page);
  const resourceKeeper = new ResourceKeeper(pageEventHandler);
  const cacheRetriever = new CacheRetriever(cachedResponsesS3Key, returnCachedResponsesImmediately);
  const errorKeeper = new ErrorKeeper(pageEventHandler);
  
  const thirdPartyTagDetector = new ThirdPartyTagDetector({ 
    firstPartyUrl: firstPartyRequestUrl, 
    urlPatternsToAllow: thirdPartyTagUrlPatternsToAllow,
    allowAllThirdPartyTags: allowAllThirdPartyTags,
    thirdPartyTagUrlPatternsToNeverAllow: thirdPartyTagUrlPatternsToNeverAllow
  });

  const pageManipulator = new PageManipulator({
    page: page, 
    pageUrl: pageUrlToPerformAuditOn, 
    overrideInitialHTMLRequestWithManipulatedPage: overrideInitialHTMLRequestWithManipulatedPage,
    cacheRetriever: cacheRetriever,
    tagInjector: new TagInjector(thirdPartyTagUrlsAndRulesToInject),
    monkeyPatcher: new MonkeyPatcher(thirdPartyTagDetector),
    imageScrubber: new ImageScrubber({ stripAllImages: stripAllImages, pageEventHandler: pageEventHandler }),
    thirdPartyTagScrubber: new ThirdPartyTagScrubber({ thirdPartyTagDetector: thirdPartyTagDetector, pageEventHandler: pageEventHandler }),
    options: { inlineInjectedScriptTags: inlineInjectedScriptTags }
  });

  const requestInterceptor = new RequestInterceptor({ 
    page: page,
    pageManipulator: pageManipulator, 
    thirdPartyTagDetector: thirdPartyTagDetector,
    cacheRetriever: cacheRetriever, 
    pageEventHandler: pageEventHandler,
    blockImageRequests: stripAllImages
  })

  const screenRecorder = new ScreenRecorder({
    page: page,
    enabled: enableScreenRecording,
    options: { filenamePrefix: uniqueFilename }
  })

  const validityChecker = new ValidityChecker({
    page: page,
    inflightRequests: requestInterceptor.inflightRequests,
    resourceKeeper: resourceKeeper,
    ensureInjectedTagHasLoaded: thirdPartyTagUrlsAndRulesToInject.length > 0,
    throwErrorIfDOMCompleteIsZero: throwErrorIfDOMCompleteIsZero
  })

  const performanceMetricsHandler = new PerformanceMetricsHandler({ 
    page: page,
    pageEventHandler: pageEventHandler,
    includePageLoadResources: includePageLoadResources
  });

  const tracer = new Tracer({
    page: page,
    cdpSession: puppeteerModerator.cdpSession,
    enabled: true,
    filename: uniqueFilename
  });
  
  const speedIndexComposer = new SpeedIndexComposer(tracer.localFilePath, uniqueFilename, { uploadFramesToS3: uploadFilmstripFramesToS3 });
  const mainThreadAnalyzer = new MainThreadAnalyzer(tracer.localFilePath);

  const auditRunner = new AuditRunner({
    page: page,
    urlToAudit: pageUrlToPerformAuditOn,
    tracer: tracer,
    screenRecorder: screenRecorder,
    requestInterceptor: requestInterceptor,
    performanceMetricsHandler: performanceMetricsHandler,
    validityChecker: validityChecker,
    options: { 
      navigationWaitUntil: navigationWaitUntil,
      navigationTimeoutMs: navigationTimeoutMs,
      networkToEmulate: 'Regular4G',
      userAgent: userAgent,
      scrollPage: scrollPage
    }
  });

  try {
    await auditRunner.runPerformanceAudit();
    await puppeteerModerator.shutdown();
  } catch(err) {
    error = err.message;
    successful = false;
    console.log(`Encountered error in performance audit`);
    console.log(err);
    console.trace();
    console.log('\n\nCleaning up lambda environment...');
    try {
      await screenRecorder._stopRecording();
      screenRecorder._removeLocalRecordingFile();
      pageManipulator._clearOverriddenPage();
    } catch(e) {
      console.log(`Failed to cleanup Lambda environment: ${e}`);
    }
    await puppeteerModerator.shutdown();
  }

  const costPerGigabyteMs = 0.0000166667 / 1_000;
  const allocatedGigabytes = parseInt(process.env.AWS_LAMBDA_FUNCTION_MEMORY_SIZE) / 1_000;
  const executionTimeMs = Date.now() - startTime;
  const estimatedCost = costPerGigabyteMs * allocatedGigabytes * executionTimeMs;

  let mainThreadResults = {
    total_execution_ms_for_tag: null,
    blocking_execution_ms_for_tag: null,
    tags_long_tasks: null
  };
  const blockingTasksAndMainThreadExecutionMs = allowAllThirdPartyTags ? 
                                                  mainThreadAnalyzer.mainThreadExecutionForUrl(resourceKeeper.thirdPartyTagUrlsAllowed()) :
                                                  thirdPartyTagUrlsAndRulesToInject.length > 0 ?
                                                    mainThreadAnalyzer.mainThreadExecutionForUrl(event.tag_url_being_audited) :
                                                    null;  
  if(blockingTasksAndMainThreadExecutionMs) {
    mainThreadResults = {
      entire_main_thread_executions_ms: blockingTasksAndMainThreadExecutionMs.allMainThreadExecutionsMs,
      entire_main_thread_blocking_executions_ms: blockingTasksAndMainThreadExecutionMs.allMainThreadBlockingExecutionMs,
      total_main_thread_execution_ms_for_tag: blockingTasksAndMainThreadExecutionMs.totalExecutionMsForUrlPatterns,
      total_main_thread_blocking_execution_ms_for_tag: blockingTasksAndMainThreadExecutionMs.totalMainThreadBlockingMsForUrlPatterns,
      tags_long_tasks: blockingTasksAndMainThreadExecutionMs.longTasksForUrlPatterns
    }
  }
  const auditResults = {
    success: successful,
    error: error,
    execution_time_ms: executionTimeMs,
    results: performanceMetricsHandler.performanceResults() || {},
    tracing_results_s3_url: tracer.s3Url(),
    speed_index: await speedIndexComposer.gatherSpeedIndexResults() || {},
    main_thread_results: mainThreadResults,
    screen_recording: {
      s3_url: screenRecorder.recordingS3Url(),
      ms_to_stop_recording: screenRecorder.msTookToStop(),
      error_message: screenRecorder.failedRecordingErrorMessage()
    },
    blocked_resources: resourceKeeper.resourcesBlocked() || [],
    completed_requests: requestInterceptor.completedRequests || [],
    cached_requests: resourceKeeper.requestsCached() || [],
    not_cached_requests: resourceKeeper.requestsNotCached() || [],
    third_party_tags_allowed: resourceKeeper.thirdPartyTagUrlsAllowed() || [],
    potential_errors: {
      uncaught_errors: errorKeeper.pageUncaughtErrors(),
      failed_network_requests: errorKeeper.failedNetworkRequests(),
      console_errors: errorKeeper.pageConsoleErrors()
    },
    // logs: logger.logs,
    aws_request_id: context.awsRequestId,
    aws_log_group_name: context.logGroupName,
    aws_log_stream_name: context.logStreamName,
    aws_trace_id: process.env._X_AMZN_TRACE_ID,
    aws_estimated_lambda_cost: estimatedCost
  }

  const performanceAuditResultsS3Url = await uploadToS3({ 
    Key: `${event.executed_step_function_uid || pageUrlToPerformAuditOn.replace(/\/|\:|\\|\./g, '_')}-RESULT-${Date.now()}-${parseInt(Math.random() * 100000)}.json`,
    Body: JSON.stringify(auditResults)
  })

  return {
    requestPayload: event,
    responsePayload: { performance_audit_results_s3_url: performanceAuditResultsS3Url },
    jsonResults: process.env.INCLUDE_RAW_AUDIT_RESULTS_IN_RESPONSE === 'true' ? auditResults : null
  };
}

module.exports.runPerformanceAudit = runPerformanceAudit;