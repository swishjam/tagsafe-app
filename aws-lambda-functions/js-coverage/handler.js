'use strict';

const PuppeteerModerator = require('./src/puppeteerModerator'),
        JsCoverageHandler = require('./src/jsCoverageHandler'),
        fs = require('fs');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { urlToRunOn, tagToCalculateCoverage, waitUntil = 'networkidle0' } = event;

  const puppeteerModerator = new PuppeteerModerator;
  const page = await puppeteerModerator.launch();

  await page.coverage.startJSCoverage({ includeRawScriptCoverage: true });
  await page.goto(urlToRunOn, { waitUntil: waitUntil });

  const jsCoverageHandler = new JsCoverageHandler(page, tagToCalculateCoverage);
  const coverageResults = jsCoverageHandler.measureCoverage();
  await page.metrics();

  fs.writeFileSync('./raw-coverage.json', JSON.stringify(coverageResults));
  
  await puppeteerModerator.shutdown();
}