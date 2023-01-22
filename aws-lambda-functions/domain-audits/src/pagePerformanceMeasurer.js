const PuppeteerModerator = require('./puppeteerModerator');

module.exports = class PagePerformanceMeasurer {
  static async measureThirdPartyImpact(page_url, first_party_urls) {
    const [pagePerfWithoutThirdPartyTags, pagePerfWithThirdPartyTags] = await Promise.all([
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, true),
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, false)
    ])

    return {
      ScriptDuration: {
        withTags: pagePerfWithThirdPartyTags['ScriptDuration'],
        withoutTags: pagePerfWithoutThirdPartyTags['ScriptDuration'],
        ...PagePerformanceMeasurer._calcImpact('ScriptDuration', pagePerfWithoutThirdPartyTags, pagePerfWithThirdPartyTags)
      },
      TaskDuration: {
        withTags: pagePerfWithThirdPartyTags['TaskDuration'],
        withoutTags: pagePerfWithoutThirdPartyTags['TaskDuration'],
        ...PagePerformanceMeasurer._calcImpact('TaskDuration', pagePerfWithoutThirdPartyTags, pagePerfWithThirdPartyTags)
      },
      DOMComplete: {
        withTags: pagePerfWithThirdPartyTags['DOMComplete'],
        withoutTags: pagePerfWithoutThirdPartyTags['DOMComplete'],
        ...PagePerformanceMeasurer._calcImpact('DOMComplete', pagePerfWithoutThirdPartyTags, pagePerfWithThirdPartyTags)
      },
      DOMInteractive: {
        withTags: pagePerfWithThirdPartyTags['DOMInteractive'],
        withoutTags: pagePerfWithoutThirdPartyTags['DOMInteractive'],
        ...PagePerformanceMeasurer._calcImpact('DOMInteractive', pagePerfWithoutThirdPartyTags, pagePerfWithThirdPartyTags)
      },
      DOMLoading: {
        withTags: pagePerfWithThirdPartyTags['DOMLoading'],
        withoutTags: pagePerfWithoutThirdPartyTags['DOMLoading'],
        ...PagePerformanceMeasurer._calcImpact('DOMLoading', pagePerfWithoutThirdPartyTags, pagePerfWithThirdPartyTags)
      },
      FirstContentfulPaint: {
        withTags: pagePerfWithThirdPartyTags['FirstContentfulPaint'],
        withoutTags: pagePerfWithoutThirdPartyTags['FirstContentfulPaint'],
        ...PagePerformanceMeasurer._calcImpact('FirstContentfulPaint', pagePerfWithoutThirdPartyTags, pagePerfWithThirdPartyTags)
      },
    }
  }

  static async _measurePagePerformance(page_url, first_party_urls, blockThirdPartyTags) {
    const puppeteerModerator = new PuppeteerModerator();
    const page = await puppeteerModerator.launch();

    if(blockThirdPartyTags) {
      await page.setRequestInterception(true);
      page.on('request', async req => {
        const isFirstParty = first_party_urls.find(url => new URL(url).hostname === new URL(req.url()).hostname)
        if (req.resourceType() === 'script' && !isFirstParty) {
          console.log(`Blocking request to ${req.url()}`)
          await req.abort();
        } else {
          await req.continue();
        }
      })
    }

    await page.goto(page_url, { waitUntil: 'networkidle2' });

    const PageMetrics = await page.metrics();
    page.on('console', log => console.log(log.text()))
    const PerfMetrics = await page.evaluate(() => {
      console.log(`DOM Complete timestamp? ${performance.timing.domComplete}`);
      console.log(`Navigation Start timestamp: ${performance.timing.navigationStart}`);
      console.log(performance.timing.domComplete - performance.timing.navigationStart);
      return {
        DOMComplete: performance.timing.domComplete - performance.timing.navigationStart,
        DOMInteractive: performance.timing.domInteractive - performance.timing.navigationStart,
        DOMLoading: performance.timing.domLoading - performance.timing.navigationStart,
        FirstContentfulPaint: performance.getEntriesByName('first-contentful-paint')[0].startTime
      }
    });

    await puppeteerModerator.shutdown();
    return { ...PageMetrics, ...PerfMetrics }
  }

  static _calcImpact(metric, withoutTagsPerf, withTagsPerf) {
    const impact = withTagsPerf[metric] - withoutTagsPerf[metric];
    return {
      impact,
      percentImpact: (impact / withTagsPerf[metric]) * 100,
    }
  }
}