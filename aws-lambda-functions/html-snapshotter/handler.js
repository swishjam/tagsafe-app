'use strict';

const Snapshotter = require('./src/snapshotter'),
      PageManipulator = require('./src/pageManipulator');

require('dotenv').config();

module.exports.handle = async (event, context) => {
  const url = event.url;
  const initialHtmlContentS3Key = event.initial_html_content_s3_key;
  const thirdPartyTagUrlsAndRulesToInject = event.third_party_tag_urls_and_rules_to_inject;
  const thirdPartyTagUrlPatternsToAllow = (event.third_party_tag_url_patterns_to_allow || []).concat(thirdPartyTagUrlsAndRulesToInject.map(urlAndRule => urlAndRule.url));
  const additionalWaitMs = parseInt(typeof event.additional_wait_ms === 'undefined' ? (process.env.ADDITIONAL_WAIT_MS || '5000') : event.additional_wait_ms);
  const continueOnNavigationTimeout = typeof event.continue_on_navigation_timeout === 'undefined' ? process.env.CONTINUE_ON_NAVIGATION_TIMEOUT === 'true' : event.continue_on_navigation_timeout === 'true';
  const navigationTimeoutMs = parseInt(typeof event.navigation_timeout_ms === 'undefined' ? (process.env.NAVIGATION_TIMEOUT_MS || '60000') : event.navigation_timeout_ms);

  console.log(`
    Beginning html-snapshotter with:
    URL: ${url}
    Initial HTML Content S3 URL: ${initialHtmlContentS3Key}
    Third Party Tag URLs and Rules to Inject: ${thirdPartyTagUrlsAndRulesToInject.map(urlAndRule => `${urlAndRule.url} -> ${urlAndRule.load_type}`).join(', ')}
    Third Party Tag URLs to Allow: ${thirdPartyTagUrlPatternsToAllow.join(', ')}

    Additional Wait ms: ${additionalWaitMs}
    Continue on Timeout: ${continueOnNavigationTimeout}
    Navigation Timeout ms: ${navigationTimeoutMs}
  `)

  const pageManipulator = new PageManipulator({
    // url: url,
    initialHtmlContentS3Key: initialHtmlContentS3Key,
    thirdPartyTagUrlsAndRulesToInject: thirdPartyTagUrlsAndRulesToInject,
    thirdPartyTagUrlPatternsToAllow: thirdPartyTagUrlPatternsToAllow,
  })

  const snapshotter = new Snapshotter({ 
    url: url,
    pageManipulator: pageManipulator,
    options: {
      additionalWaitMs: additionalWaitMs,
      continueOnNavigationTimeout: continueOnNavigationTimeout,
      navigationTimeoutMs: navigationTimeoutMs 
    }
  })

  await snapshotter.takeSnapshot();

  console.log(`
    Completed html-snapshotter with results:
    Navigation Timed Out?: ${snapshotter.navigationTimedOut}
    HTML S3 URL: ${snapshotter.htmlS3Location}
    Screenshot S3 URL: ${snapshotter.screenshotS3Location}
    Third Party Tags Blocked: ${pageManipulator.thirdPartyTagsBlocked.join(', ')}
    Third Party Tags Allowed: ${pageManipulator.thirdPartyTagsAllowed.join(', ')}
    First Party JS Requests: ${pageManipulator.firstPartyJavascriptRequests.join(', ')}
  `)

  return {
    navigation_timed_out: snapshotter.navigationTimedOut,
    html_s3_url: snapshotter.htmlS3Location,
    screenshot_s3_url: snapshotter.screenshotS3Location,
    third_party_tags_blocked: pageManipulator.thirdPartyTagsBlocked,
    third_party_tags_allowed: pageManipulator.thirdPartyTagsAllowed,
    first_party_js_requests: pageManipulator.firstPartyJavascriptRequests,
    aws_request_id: context.awsRequestId,
    aws_log_stream_name: context.logStreamName,
    aws_trace_id: process.env._X_AMZN_TRACE_ID
  }
}
