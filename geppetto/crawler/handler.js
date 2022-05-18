'use strict';

const Crawler = require('./src/urlCrawler'),
      RequestInterceptor = require('./src/requestInterceptor');

require('dotenv').config();

module.exports.handle = async (event, context) => {
  console.log(`EXECUTED LAMBDA FUNCTION UID: ${event.executed_step_function_uid}`);
  console.log(`event: ${JSON.stringify(event)}`);

  context.serverlessSdk.tagEvent('executed-lambda-function-uid', event.executed_step_function_uid || 'none');
  let error;
  const pageUrl = event.url;
  const puppeteerPageWaitUntil = event.page_navigation_wait_until || process.env.PUPPETEER_PAGE_NAVIGATION_WAIT_UNTIL || 'networkidle2';
  const puppeteerPageTimeoutMs = parseInt(event.page_navigation_timeout || process.env.PUPPETEER_PAGE_NAVIGATION_TIMEOUT_MS || '0');
  const firstPartyUrlPatterns = event.first_party_url_patterns || [];
  const navigationMsToHaultExecutionAndReturnResults = event.navigation_ms_to_hault_execution_and_return_results || 60_000;

  console.log(`
    Beginning URL Crawl with:
    Page URL: ${pageUrl}
    First Party URL Patterns: ${firstPartyUrlPatterns.join(', ')}
    Navigation Wait Until: ${puppeteerPageWaitUntil}
    Navigation Timeout ms: ${puppeteerPageTimeoutMs}
    Navigation ms to hault execution and return results: ${navigationMsToHaultExecutionAndReturnResults}
  `)

  const requestInterceptor = new RequestInterceptor({
    url: pageUrl,
    firstPartyUrlPatterns: firstPartyUrlPatterns
  })

  const crawler = new Crawler({ 
    url: pageUrl,
    requestInterceptor: requestInterceptor,
    options: {
      puppeteerPageTimeoutMs: puppeteerPageTimeoutMs, 
      puppeteerPageWaitUntil: puppeteerPageWaitUntil,
      stopIfNavigationExceeds: navigationMsToHaultExecutionAndReturnResults
    }
  });
  
  await crawler.crawlForThirdPartyTags()

  return {
    requestPayload: event,
    responsePayload: {
      tag_urls: requestInterceptor.thirdPartyTags || {},
      first_party_js_tags: requestInterceptor.firstPartyJsFiles || {},
      first_party_bytes: requestInterceptor.firstPartyJsBytes,
      third_party_bytes: requestInterceptor.thirdPartyJsBytes,
      navigation_fully_completed: crawler.navigationFullyCompleted,
      error: error,
      aws_request_id: context.awsRequestId,
      aws_log_stream_name: context.awsLogStreamName,
      aws_trace_id: process.env._X_AMZN_TRACE_ID
    }
  }
}
