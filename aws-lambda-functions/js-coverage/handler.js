'use strict';

const PuppeteerModerator = require('./src/puppeteerModerator');
const JsCoverageHandler = require('./src/jsCoverageHandler');
const ScriptManipulator = require('./src/scriptManipulator');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { 
    tag_url_to_inject, 
    tag_to_inject_load_strategy,
    tag_url_patterns_to_block,
    page_url, 
    coverage_multiplier = 1.5,
    navigation_wait_until = 'domcontentloaded' 
  } = event;

  if(!tag_url_to_inject || !tag_to_inject_load_strategy || !tag_url_patterns_to_block || !page_url) {
    console.error('Event payload received:')
    console.log(JSON.stringify(event));
    throw new Error(`
      Invalid JSCoverage invocation, missing required params. 
      Must include: \`tag_url_to_inject\`, \`tag_to_inject_load_strategy\`, \`tag_url_patterns_to_block\`, and \`page_url\`.
    `)
  }

  const puppeteerModerator = new PuppeteerModerator;
  const page = await puppeteerModerator.launch();

  const scriptManipulator = new ScriptManipulator({ 
    page, 
    urlPatternsToBlock: tag_url_patterns_to_block, 
    urlToInject: tag_url_to_inject, 
    urlToInjectLoadStrategy : tag_to_inject_load_strategy,
  });

  await Promise.all([
    scriptManipulator.blockRequestsToUrlPatterns(),
    scriptManipulator.injectScriptOnNewDocument(),
    page.coverage.startJSCoverage({ includeRawScriptCoverage: true })
  ])

  console.log(`Navigating to ${page_url}......`);
  await page.goto(page_url, { waitUntil: navigation_wait_until });

  await new Promise(resolve => setTimeout(resolve, 5_000));

  const jsCoverageHandler = new JsCoverageHandler(page, tag_url_to_inject);
  console.log(`Measuring coverage for ${tag_url_to_inject}......`);
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