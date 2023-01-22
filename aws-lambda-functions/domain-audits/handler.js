'use strict';

const PagePerformanceMeasurer = require('./src/pagePerformanceMeasurer');
const NetworkAnalyzer = require('./src/networkAnalyzer');

require('dotenv').config();

module.exports.handle = async (event, _context) => {
  const { 
    page_url, 
    navigation_wait_until = 'networkidle2',
    first_party_urls = [page_url]
  } = event;

  console.log(`Analyzing third party impact to ${page_url} (first party URLs = ${first_party_urls.join(', ')})`);

  const [perfResults, dns] = await Promise.all([
    PagePerformanceMeasurer.measureThirdPartyImpact(page_url, first_party_urls),
    NetworkAnalyzer.analyzeNetworkRequests(page_url, first_party_urls),
  ])

  return { perfResults, dns };
}