'use strict';

const ScriptRunner = require('./src/scriptRunner'),
      Logger = require('./src/logger'),
      ScreenRecorder = require('./src/screenRecorder'),
      TagManipulator = require('./src/tagManipulator'),
      ExposedFunctionsHandler = require('./src/exposedFunctionsHandler'),
      DomManipulator = require('./src/domManipulator');

require('dotenv').config();

module.exports.handle = async (event, context) => {
  let start = Date.now();
  console.log(`EXECUTED LAMBDA FUNCTION UID: ${event.executed_step_function_uid}`);
  context.serverlessSdk.tagEvent('executed-step-function-uid', event.executed_step_function_uid);
  const puppeteerScript = event.puppeteer_script;
  const expectedResults = event.expected_results;
  const firstPartyUrl = event.first_party_url;
  const thirdPartyTagUrlsAndRulesToInject = event.third_party_tag_urls_and_rules_to_inject;
  const thirdPartyTagUrlPatternsToAllow = (event.third_party_tag_url_patterns_to_allow || []).concat(thirdPartyTagUrlsAndRulesToInject.map(urlAndRule => urlAndRule.url));
  
  const maxScriptExecutionMs = parseInt(event.max_script_execution_ms || process.env.MAX_SCRIPT_EXECUTION_MS || 30_000);
  const includeScreenRecordingOnPassingScript = event.include_screen_recording_on_passing_script === 'true';
  const screenRecorderEnabled = (typeof event.enable_screen_recording === 'undefined' ? process.env.ENABLE_SCREEN_RECORDING === 'true' : event.enable_screen_recording === 'true')
  const screenRecorderFileFormat = event.screen_recording_file_format || process.env.SCREEN_RECORDING_FILE_FORMAT || 'mp4';
  const screenRecorderFps = parseInt(event.screen_recording_fps || process.env.SCREEN_RECORDING_FPS || 15);

  console.log(`
    Beginning functional-test-run v1.01 with:
    Puppeteer Script: 
    
    ${puppeteerScript}

    Expected Results: ${expectedResults}
    First Party URL: ${firstPartyUrl}
    Third Party Tag URLs and Rules to Inject: ${thirdPartyTagUrlsAndRulesToInject.map(urlAndRule => `${urlAndRule.load_type} - ${urlAndRule.url}`).join(', ')}
    Third Party Tag URLs to Allow: ${thirdPartyTagUrlPatternsToAllow.join(', ')}
    Max Script Execution ms: ${maxScriptExecutionMs}
    Screen Recorder Enabled: ${screenRecorderEnabled}
    Include Screen Recording on Passing Script: ${includeScreenRecordingOnPassingScript}
    Screen Recorder File Format: ${screenRecorderFileFormat}
    Screen Recorder FPS: ${screenRecorderFps}
  `)

  const logger = new Logger();
  const hashedScript = puppeteerScript.split('').reduce((a,b)=>{a=((a<<5)-a)+b.charCodeAt(0);return a&a},0);

  const screenRecorder = new ScreenRecorder({
    enabled: screenRecorderEnabled,
    millisecondsLeftFunction: context.getRemainingTimeInMillis,
    options: {
      filenamePrefix: hashedScript,
      fps: screenRecorderFps, 
      fileFormat: screenRecorderFileFormat
    }
  })

  const exposedFunctionsHandler = new ExposedFunctionsHandler({ 
    logger: logger,
    urlsToWaitFor: thirdPartyTagUrlsAndRulesToInject.map(urlAndRule => urlAndRule.url),
    filenamePrefix: hashedScript
  })

  const tagManipulator = new TagManipulator({
    firstPartyUrl: firstPartyUrl,
    thirdPartyTagUrlPatternsToAllow: thirdPartyTagUrlPatternsToAllow,
    thirdPartyTagUrlsAndRulesToInject: thirdPartyTagUrlsAndRulesToInject
  })

  const runner = new ScriptRunner({ 
    puppeteerScript: puppeteerScript,
    expectedResults: expectedResults,
    logger: logger,
    screenRecorder: screenRecorder,
    tagManipulator: tagManipulator,
    exposedFunctionsHandler: exposedFunctionsHandler,
    domManipulator: new DomManipulator(),
    options: {
      includeScreenRecordingOnPassingScript: includeScreenRecordingOnPassingScript,
      maxScriptExecutionMs: maxScriptExecutionMs
    }
  })

  await runner.run();

  const results = {
    passed: runner.passed,
    script_results: runner.scriptResults,
    script_execution_ms: runner.scriptExecutionMs,
    screen_recording: {
      s3_url: screenRecorder.s3Url,
      ms_to_stop: screenRecorder.msTookToStop,
      failed_to_capture: screenRecorder.failedToStop,
      stop_ms_threshold: screenRecorder.msAvailableToStopRecording
    },
    third_party_tags_blocked: tagManipulator.thirdPartyTagsBlocked,
    third_party_tags_allowed: tagManipulator.thirdPartyTagsAllowed,
    requests_allowed: tagManipulator.requestsAllowed,
    logs: logger.userLogs,
    failure: {
      message: runner.failureMessage,
      stack: runner.failureStack
    },
    execution_time_ms: Date.now() - start,
    completed_at: (new Date()).toLocaleString('en-us', { timeZone: 'America/Los_Angeles' }),
    aws_request_id: context.awsRequestId,
    aws_log_stream_name: context.logStreamName,
    aws_trace_id: process.env._X_AMZN_TRACE_ID
  }


  console.log(`
    ====== Script Runner completed with: ======
    ${JSON.stringify(results)}
  `)

  return {
    requestPayload: event,
    responsePayload: results
  };
}