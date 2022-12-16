'use strict';

const PuppeteerModerator = require('./src/puppeteerModerator'),
        JsCoverageHandler = require('./src/jsCoverageHandler'),
        fs = require('fs');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { tag_url_pattern, page_url, navigation_wait_until = 'networkidle0' } = event;

  const puppeteerModerator = new PuppeteerModerator;
  const page = await puppeteerModerator.launch();

  await page.coverage.startJSCoverage({ includeRawScriptCoverage: true });
  await page.goto(page_url, { waitUntil: navigation_wait_until });

  const jsCoverageHandler = new JsCoverageHandler(page, tag_url_pattern)
  const coverageResults = await jsCoverageHandler.measureCoverage();
  await puppeteerModerator.shutdown();

  return {
    js_bytes_used: coverageResults.jsUsedBytes,
    total_js_bytes: coverageResults.totalJsBytes,
    percent_js_used: coverageResults.percentJsUsed,
    covered_js: coverageResults.coveredJs
  };
}