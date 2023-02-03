const PuppeteerModerator = require('./puppeteerModerator');
const cheerio = require('cheerio');
const fs = require('fs');

require('dotenv').config();

module.exports = class PerformanceMeasurer {
  constructor({ pageUrl, tagUrlsToTagsafeCDNMap }) {
    this.pageUrl = pageUrl;
    this.tagUrlsToTagsafeCDNMap = tagUrlsToTagsafeCDNMap;
  }

  async measurePerformance() {
    console.log(`Measuring the page performance of ${this.pageUrl}...`);

    const overriddenHTML = await this._getPageContentWithOverridenScriptTags();
    fs.writeFileSync(`overridden.html`, overriddenHTML);

    const puppeteerModerator = new PuppeteerModerator()
    const page = await puppeteerModerator.launch();

    await page.setRequestInterception(true);
    page.on('request', (request) => {
      if (request.resourceType() === 'document' && page.url() === 'about:blank') {
        console.log('Intercepting initial HTML request with overridden HTML...')
        request.respond({
          status: 200,
          contentType: 'text/html',
          body: overriddenHTML,
        });
      } else {
        request.continue();
      }
    });

    console.log(`Navigating to ${this.pageUrl}...`);
    await page.goto(this.pageUrl, { waituntil: 'domcontentloaded' });
    fs.writeFileSync('page.html', await page.content());

    console.log(`Measuring performance metrics...`);
    const perfMetrics = await this._gatherPerformanceMetrics(page);

    await puppeteerModerator.shutdown();
    return { ...perfMetrics };
  }

  async _getPageContentWithOverridenScriptTags() {
    const resp = await fetch(this.pageUrl);
    const html = await resp.text();
    const $ = cheerio.load(html);
    const scope = this;
    console.log(`Looping through all script tags and replacing them with Tagsafe CDN from: ${scope.tagUrlsToTagsafeCDNMap}`)
    $('script[src]').each((_i, el) => {
      const src = $(el).attr('src');
      const tagsafeCDNUrlForScriptTag = scope.tagUrlsToTagsafeCDNMap[src];
      console.log(`tagsafeCDNUrlForScriptTag: ${tagsafeCDNUrlForScriptTag} (src: ${src})`);
      if (tagsafeCDNUrlForScriptTag) {
        console.log(`Replacing third-party tag ${src} with ${tagsafeCDNUrlForScriptTag}...`);
        $(el).attr('src', tagsafeCDNUrlForScriptTag);
      }
    });
    $('head').prepend(`
      <script>
        (function() {
          const tagUrlsToTagsafeCDNMap = ${JSON.stringify(scope.tagUrlsToTagsafeCDNMap)};

          const ogAppendChild = Element.prototype.appendChild;
          Element.prototype.appendChild = function() {
            if (arguments[0].tagName === 'SCRIPT') {
              const scriptSrc = arguments[0].getAttribute('src');
              const tagsafeCDNUrlForScriptTag = tagUrlsToTagsafeCDNMap[scriptSrc];
              if(tagsafeCDNUrlForScriptTag) {
                console.log('Replacing third-party tag ' + scriptSrc + ' with ' + tagsafeCDNUrlForScriptTag + '...');
                arguments[0].setAttribute('src', tagsafeCDNUrlForScriptTag);
              }
            }
            return ogAppendChild.apply(this, arguments);
          };

          const ogInsertBefore = Element.prototype.insertBefore;
          Element.prototype.insertBefore = function() {
            if (arguments[0].tagName === 'SCRIPT') {
              const scriptSrc = arguments[0].getAttribute('src');
              const tagsafeCDNUrlForScriptTag = tagUrlsToTagsafeCDNMap[scriptSrc];
              if(tagsafeCDNUrlForScriptTag) {
                console.log('Replacing third-party tag ' + scriptSrc + ' with ' + tagsafeCDNUrlForScriptTag + '...');
                arguments[0].setAttribute('src', tagsafeCDNUrlForScriptTag);
              }
            }
            return ogInsertBefore.apply(this, arguments);
          };
        })();
      </script>
    `)
    return $.html();
  }

  async _gatherPerformanceMetrics(page) {
    return await page.evaluate(() => {
      const performance = window.performance;
      const timing = performance.timing;
      const navigation = performance.getEntriesByType('navigation')[0];
      const navigationStart = timing.navigationStart;
      const domContentLoadedEventEnd = timing.domContentLoadedEventEnd;
      const domContentLoadedEventStart = timing.domContentLoadedEventStart;
      const domInteractive = timing.domInteractive;
      const domLoading = timing.domLoading;
      const loadEventEnd = timing.loadEventEnd;
      const loadEventStart = timing.loadEventStart;
      const responseEnd = timing.responseEnd;
      const responseStart = timing.responseStart;
      const secureConnectionStart = timing.secureConnectionStart;
      const unloadEventEnd = timing.unloadEventEnd;
      const unloadEventStart = timing.unloadEventStart;
      const firstPaint = navigation.toJSON().firstPaint;
      const firstContentfulPaint = navigation.toJSON().firstContentfulPaint;
      const firstInputDelay = navigation.toJSON().firstInputDelay;
      const firstMeaningfulPaint = navigation.toJSON().firstMeaningfulPaint;
      const firstCPUIdle = navigation.toJSON().firstCPUIdle;
      const firstInteractive = navigation.toJSON().firstInteractive;
      const estimatedInputLatency = navigation.toJSON().estimatedInputLatency;
      const serverResponseTime = responseEnd - responseStart;
      const domProcessingTime = domContentLoadedEventEnd - domContentLoadedEventStart;
      const domInteractiveTime = domInteractive - domLoading;
      const domContentLoadedTime = loadEventStart - domContentLoadedEventStart;
      const loadTime = loadEventEnd - loadEventStart;
      const pageLoadTime = loadEventEnd - navigationStart;
      const pageUnloadTime = unloadEventEnd - unloadEventStart;
      const connectionTime = secureConnectionStart > 0 ? secureConnectionStart - navigationStart : 0;
      const dnsLookupTime = responseStart - navigationStart;
      const redirectTime = responseStart - navigationStart;
      const tlsHandshakeTime = secureConnectionStart > 0 ? responseStart - secureConnectionStart : 0;
      const firstPaintTime = firstPaint - navigationStart;
      const firstContentfulPaintTime = firstContentfulPaint - navigationStart;
      const firstInputDelayTime = firstInputDelay;
      const firstMeaningfulPaintTime = firstMeaningfulPaint - navigationStart;
      const firstCPUIdleTime = firstCPUIdle - navigationStart;
      const firstInteractiveTime = firstInteractive - navigationStart;
      const estimatedInputLatencyTime = estimatedInputLatency;

      let totalJsNetworkTime = 0;
      window.performance.getEntriesByType('resource').forEach(resource => {
        if (resource.initiatorType === 'script') totalJsNetworkTime += resource.duration;
      })

      return {
        totalJsNetworkTime,
        serverResponseTime,
        domProcessingTime,
        domInteractiveTime,
        domContentLoadedTime,
        loadTime,
        pageLoadTime,
        pageUnloadTime,
        connectionTime,
        dnsLookupTime,
        redirectTime,
        tlsHandshakeTime,
        firstPaintTime,
        firstContentfulPaintTime,
        firstInputDelayTime,
        firstMeaningfulPaintTime,
        firstCPUIdleTime,
        firstInteractiveTime,
        estimatedInputLatencyTime
      };
    });
  }
}