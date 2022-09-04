'use strict';

const PuppeteerModerator = require('./src/puppeteerModerator');

require('dotenv').config();

module.exports.handle = async (_event, _context) => {
  const puppeteerModerator = new PuppeteerModerator;
  const page = await puppeteerModerator.launch();
  let responseTimes = {};
  let totals = {
    totalRequests: 0,
    totalRequestsWithDns: 0,
    totalDnsTime: 0,
    totalSslTime: 0,
    totalConnectTime: 0
  };

  page.on('response', resp => {
    if(resp.url().startsWith('https://content.canadiantire.ca')) {
      const timing = resp.timing();
      const attrs = {
        type: resp.request().resourceType(),
        totalDnsTime: timing['dnsEnd'] - timing['dnsStart'],
        totalSslTime: timing['sslEnd'] - timing['sslStart'],
        totalConnectTime: timing['connectEnd'] - timing['connectStart'],
        raw: {...timing}
      };
      responseTimes[resp.url()] = attrs;
      totals['totalDnsTime'] += attrs['totalDnsTime'];
      totals['totalSslTime'] += attrs['totalSslTime'];
      totals['totalConnectTime'] += attrs['totalConnectTime'];
      totals['totalRequests']++;
      if(attrs['totalDnsTime'] > 0) totals['totalRequestsWithDns']++
    }
  });
  
  await page.goto('https://www.canadiantire.ca', { waitUntil: 'networkidle2' });
  await puppeteerModerator.shutdown();
  return { responseTimes, totals };
}