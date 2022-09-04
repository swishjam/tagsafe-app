'use strict';

const PerformanceMeasurer = require('./src/performanceMeasurer'),
        PuppeteerModerator = require('./src/puppeteerModerator'),
        Tracer = require('./src/tracer');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { urlToRunOn, tagToCalculateCoverage, waitUntil = 'networkidle0' } = event;

  const puppeteerModerator = new PuppeteerModerator;
  const page = await puppeteerModerator.launch();
  const tracer = new Tracer({ page: page });
  const performanceMeasurer = new PerformanceMeasurer({ page: page, traceFilePath: tracer.localFilePath, tagUrl: tagToCalculateCoverage });

  // await page.setRequestInterception(true);
  // page.on('request', async request => {
  //   if(request.url() === tagToCalculateCoverage) {
  //     console.log(`Aborting ${request.url()}!!!!!!!`);
  //     await request.abort();
  //   } else {
  //     await request.continue();
  //   }
  // })
  
  await tracer.startTracing();
  await page.goto(urlToRunOn, { waitUntil: waitUntil });
  await tracer.stopTracing();
  const perfResults = await performanceMeasurer.measurePerformanceOfTag();
  console.log(perfResults);
  
  await puppeteerModerator.shutdown();
}


// WITH TAG: { domInteractive: 2551, domComplete: 3287 }
//           { domInteractive: 1262, domComplete: 2149 }
//           { domInteractive: 1330, domComplete: 2247 }

// WITHOUT TAG: { domInteractive: 1318, domComplete: 2141 }
//              { domInteractive: 1104, domComplete: 1845 }
//              { domInteractive: 1336, domComplete: 2079 }