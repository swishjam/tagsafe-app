'use strict';

const PuppeteerModerator = require('./src/puppeteerModerator');
const JsCoverageHandler = require('./src/jsCoverageHandler');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { 
    tag_url_pattern, 
    page_url, 
    coverage_multiplier = 1.5,
    navigation_wait_until = 'networkidle0' 
  } = event;

  const puppeteerModerator = new PuppeteerModerator;
  const page = await puppeteerModerator.launch();

  await page.coverage.startJSCoverage({ includeRawScriptCoverage: true });
  console.log(`Navigating to ${page_url}......`);
  await page.goto(page_url, { waitUntil: navigation_wait_until });

  const jsCoverageHandler = new JsCoverageHandler(page, tag_url_pattern)
  console.log(`Measuring coverage for ${tag_url_pattern}......`);
  const coverageResults = await jsCoverageHandler.measureCoverage();
  await puppeteerModerator.shutdown();

  const score = coverageResults.percentJsUsed <= 1 ? 
                  0 : coverageResults.percentJsUsed * coverage_multiplier > 100 ? 
                  100 : coverageResults.percentJsUsed * coverage_multiplier;

  const responsePayload = {
    score,
    raw_results: {
      js_bytes_used: coverageResults.jsUsedBytes,
      total_js_bytes: coverageResults.totalJsBytes,
      percent_js_used: coverageResults.percentJsUsed,
      covered_js: coverageResults.coveredJs
    }
  }
  return { responsePayload, requestPayload: event }
}