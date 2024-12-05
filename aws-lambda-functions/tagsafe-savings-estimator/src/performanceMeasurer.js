const PuppeteerModerator = require('./puppeteerModerator');
const PuppeteerHar = require('puppeteer-har');

require('dotenv').config();

module.exports = class PerformanceMeasurer {
  constructor({ pageUrl, resourceUrlsToTagsafeCDNMap }) {
    this.pageUrl = pageUrl;
    this.resourceUrlsToTagsafeCDNMap = resourceUrlsToTagsafeCDNMap;
    this.ignoreQueryParamsWhenOverridingRequests = true;
    this.numTagsafeHostedResources = 0;
    this.totalNumRequests = 0;
  }

  async measurePerformance() {
    console.log(`Measuring the page performance of ${this.pageUrl}...`);
    const puppeteerModerator = new PuppeteerModerator()
    const page = await puppeteerModerator.launch();
    
    const har = new PuppeteerHar(page);
    const fileName = `${Object.keys(this.resourceUrlsToTagsafeCDNMap).length > 0 ? 'tagsafe-hosted-' : 'not-tagsafe-hosted-'}-${Date.now()}-${Math.random() * 1_000_000_000_000}-results.har`;
    await har.start({ path: `./${fileName}` });

    await page.setRequestInterception(true);
    page.on('request', request => {
      const parsedUrl = new URL(request.url());
      const tagsafeCDNUrl = this.resourceUrlsToTagsafeCDNMap[request.url()] || this.resourceUrlsToTagsafeCDNMap[`${parsedUrl.protocol }//${parsedUrl.host}${parsedUrl.pathname}`];
      if(tagsafeCDNUrl) {
        console.log(`Intercepting ${request.resourceType()} resource request to ${request.url()} and overriding it with ${tagsafeCDNUrl}`);
        this.numTagsafeHostedResources += 1;
      }
      this.totalNumRequests += 1;
      request.continue({ url: tagsafeCDNUrl || request.url() });
    })

    console.log(`Navigating to ${this.pageUrl}...`);
    await page.goto(this.pageUrl, { waituntil: 'domcontentloaded' });

    console.log(`Measuring performance metrics...`);
    const perfMetrics = await this._gatherPerformanceMetrics(page);

    await har.stop();
    console.log(`Wrote HAR file to ${fileName}`);
    await puppeteerModerator.shutdown();
    console.log(`HOSTED ${this.numTagsafeHostedResources} OF ${this.totalNumRequests} RESOURCES!!!!`);
    return { ...perfMetrics };
  }

  async _gatherPerformanceMetrics(page) {
    return await page.evaluate(() => {
      const performance = window.performance;
      const timing = performance.timing;
      const navigationStart = timing.navigationStart;
      const domContentLoadedEventEnd = timing.domContentLoadedEventEnd;
      const domContentLoadedEventStart = timing.domContentLoadedEventStart;
      const domInteractive = timing.domInteractive;
      const domLoading = timing.domLoading;
      const loadEventEnd = timing.loadEventEnd;
      const loadEventStart = timing.loadEventStart;
      const responseEnd = timing.responseEnd;
      const responseStart = timing.responseStart;
      const unloadEventEnd = timing.unloadEventEnd;
      const unloadEventStart = timing.unloadEventStart;
      const firstContentfulPaint = performance.getEntriesByName('first-contentful-paint')[0]?.startTime;
      const serverResponseTime = responseEnd - responseStart;
      const domProcessingTime = domContentLoadedEventEnd - domContentLoadedEventStart;
      const domInteractiveTime = domInteractive - domLoading;
      const domContentLoadedTime = loadEventStart - domContentLoadedEventStart;
      const loadTime = loadEventEnd - loadEventStart;
      const pageLoadTime = loadEventEnd - navigationStart;
      const pageUnloadTime = unloadEventEnd - unloadEventStart;

      let totalJsNetworkTime = 0;
      let totalNetworkTime = 0;
      window.performance.getEntriesByType('resource').forEach(resource => {
        if (resource.initiatorType === 'script') totalJsNetworkTime += resource.duration;
        totalNetworkTime += resource.duration;
      })

      return {
        numTagsafeHostedResources: this.numTagsafeHostedResources,
        totalNetworkTime,
        totalJsNetworkTime,
        serverResponseTime,
        domProcessingTime,
        domInteractiveTime,
        domContentLoadedTime,
        firstContentfulPaint,
        loadTime,
        pageLoadTime,
        pageUnloadTime,
        // connectionTime,
        // dnsLookupTime,
        // redirectTime,
        // tlsHandshakeTime,
      };
    });
  }
}