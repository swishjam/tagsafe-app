'use strict';

const PagePerformanceMeasurer = require('./src/pagePerformanceMeasurer');
const NetworkAnalyzer = require('./src/networkAnalyzer');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { 
    page_url, 
    navigation_wait_until = 'networkidle2',
    first_party_url = page_url
  } = event;

  console.log(`Analyzing third party impact to ${page_url} (first party URLs = ${first_party_url})`);

  const [perfResults, dns] = await Promise.all([
    PagePerformanceMeasurer.measureThirdPartyImpact(page_url, first_party_url),
    NetworkAnalyzer.analyzeNetworkRequests(page_url, first_party_url),
  ])

  return { perfResults, dns };
}