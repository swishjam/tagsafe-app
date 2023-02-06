const PuppeteerModerator = require('./puppeteerModerator');

require('dotenv').config();

module.exports = class PerformanceMeasurer {
  constructor({ pageUrl, tagUrlsToTagsafeCDNMap }) {
    this.pageUrl = pageUrl;
    this.tagUrlsToTagsafeCDNMap = tagUrlsToTagsafeCDNMap;
    this.numTagsafeHostedTags = 0;
  }

  async measurePerformance() {
    console.log(`Measuring the page performance of ${this.pageUrl}...`);

    const puppeteerModerator = new PuppeteerModerator()
    const page = await puppeteerModerator.launch();

    await page.setRequestInterception(true);
    page.on('request', request => {
      if(request.resourceType() === 'script') {
        const tagsafeCDNUrl = this.tagUrlsToTagsafeCDNMap[request.url()];
        if(tagsafeCDNUrl) {
          console.log(`Intercepting script tag request to ${request.url()} and overriding it with ${tagsafeCDNUrl}`);
          this.numTagsafeHostedTags += 1;
        }
        request.continue({ url: tagsafeCDNUrl || request.url() });
      } else {
        request.continue();
      }
    })

    console.log(`Navigating to ${this.pageUrl}...`);
    await page.goto(this.pageUrl, { waituntil: 'domcontentloaded' });

    console.log(`Measuring performance metrics...`);
    const perfMetrics = await this._gatherPerformanceMetrics(page);

    await puppeteerModerator.shutdown();
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
      window.performance.getEntriesByType('resource').forEach(resource => {
        if (resource.initiatorType === 'script') totalJsNetworkTime += resource.duration;
      })

      return {
        numTagsafeHostedTags: this.numTagsafeHostedTags,
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