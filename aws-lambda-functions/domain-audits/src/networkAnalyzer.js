const PuppeteerModerator = require('./puppeteerModerator');
const PuppeteerHar = require('puppeteer-har');
const fs = require('fs');
const { request } = require('http');

module.exports = class NetworkAnalyzer { 
  static async analyzeNetworkRequests(page_url, first_party_url) {
    const puppeteerModerator = new PuppeteerModerator();
    const page = await puppeteerModerator.launch();

    const har = new PuppeteerHar(page);
    await har.start({ path: 'results.har' });
    await page.goto(page_url, { waitUntil: 'networkidle2' });
    await har.stop();
    await puppeteerModerator.shutdown();

    const harData = fs.readFileSync('results.har');
    return NetworkAnalyzer._calculateThirdPartyJavascriptDnsTime(JSON.parse(harData).log.entries, first_party_url);
  }

  static _calculateThirdPartyJavascriptDnsTime(harEntries, firstPartyUrl) {
    const jsHarEntries = harEntries.filter(entry => entry.request.method === 'GET' && entry.response.content.mimeType === 'application/javascript');

    let totalDnsTime = 0;
    let totalSslTime = 0;
    let totalTime = 0;
    let totalJsBytes = 0;
    let totalThirdPartyDnsTime = 0;
    let totalThirdPartySslTime = 0;
    let totalThirdPartyTime = 0;
    let totalThirdPartyJsBytes = 0;
    let totalFirstPartyDnsTime = 0;
    let totalFirstPartySslTime = 0;
    let totalFirstPartyTime = 0;
    let totalFirstPartyJsBytes = 0;
    let thirdPartyJsHosts = [];
    let allJsRequests = [];
    let thirdPartyJsRequests = [];
    let firstPartyJsRequests = [];
    
    jsHarEntries.forEach(entry => {
      const { timings } = entry;
      const { url } = entry.request;
      const bytes = entry.response.content.size;
      const dnsTime = Math.max(timings.dns, 0);
      // const sslTime = Math.max(timings.ssl, timings.connect,  0);
      const sslTime = Math.max(timings.ssl, 0);
      const requestTime = timings.blocked + dnsTime + sslTime + timings.send + timings.wait + timings.receive;
      const data = { url, bytes, dnsTime, sslTime, requestTime };

      totalDnsTime += dnsTime;
      totalSslTime += sslTime;
      totalTime += requestTime;
      totalJsBytes += bytes;
      allJsRequests.push(data);

      if(new URL(url).hostname === new URL(firstPartyUrl).hostname) {
        totalFirstPartyDnsTime += dnsTime;
        totalFirstPartySslTime += sslTime;
        totalFirstPartyTime += requestTime;
        totalFirstPartyJsBytes += bytes;
        firstPartyJsRequests.push(data);
      } else {
        totalThirdPartyDnsTime += dnsTime;
        totalThirdPartySslTime += sslTime;
        totalThirdPartyTime += requestTime;
        totalThirdPartyJsBytes += bytes;
        thirdPartyJsHosts.push(new URL(url).hostname);
        thirdPartyJsRequests.push(data);
      }
    })

    return { 
      thirdPartyJsRequests,
      numJsRequests: allJsRequests.length,
      numThirdPartyJsRequests: thirdPartyJsRequests.length,
      numFirstPartyJsRequests: firstPartyJsRequests.length,
      numUnique3pHosts: thirdPartyJsHosts.filter((value, index, self) => self.indexOf(value) === index).length,
      totalJsBytes,
      totalDnsTime,
      totalSslTime,
      totalTime,
      totalFirstPartyDnsTime,
      totalFirstPartySslTime,
      totalFirstPartyTime,
      totalFirstPartyJsBytes,
      totalThirdPartyDnsTime,
      totalThirdPartySslTime,
      totalThirdPartyTime,
      totalThirdPartyJsBytes,
      percentOfThirdPartyJsRequestTimeIsDnsOrSsl: ((totalThirdPartyDnsTime + totalThirdPartySslTime) / totalThirdPartyTime) * 100,
      percentOfJsRequestTimeIs3p: totalThirdPartyTime / totalTime,
      percentOfJsIs3p: totalThirdPartyJsBytes / totalJsBytes
     }
  }
} 