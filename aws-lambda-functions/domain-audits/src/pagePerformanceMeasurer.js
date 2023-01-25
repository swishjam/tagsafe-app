const PuppeteerModerator = require('./puppeteerModerator');

module.exports = class PagePerformanceMeasurer {
  static async measureThirdPartyImpact(page_url, first_party_urls) {
    const [pagePerfWithoutThirdPartyTags1, pagePerfWithThirdPartyTags1] = await Promise.all([
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, true),
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, false)
    ])

    const [pagePerfWithoutThirdPartyTags2, pagePerfWithThirdPartyTags2] = await Promise.all([
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, true),
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, false)
    ])

    const [pagePerfWithoutThirdPartyTags3, pagePerfWithThirdPartyTags3] = await Promise.all([
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, true),
      PagePerformanceMeasurer._measurePagePerformance(page_url, first_party_urls, false)
    ])

    const averageScriptDurationWithTags = (pagePerfWithThirdPartyTags1.ScriptDuration + pagePerfWithThirdPartyTags2.ScriptDuration + pagePerfWithThirdPartyTags3.ScriptDuration) / 3
    const averageScriptDurationWithoutTags = (pagePerfWithoutThirdPartyTags1.ScriptDuration + pagePerfWithoutThirdPartyTags2.ScriptDuration + pagePerfWithoutThirdPartyTags3.ScriptDuration) / 3
    const averageTaskDurationWithTags = (pagePerfWithThirdPartyTags1.TaskDuration + pagePerfWithThirdPartyTags2.TaskDuration + pagePerfWithThirdPartyTags3.TaskDuration) / 3
    const averageTaskDurationWithoutTags = (pagePerfWithoutThirdPartyTags1.TaskDuration + pagePerfWithoutThirdPartyTags2.TaskDuration + pagePerfWithoutThirdPartyTags3.TaskDuration) / 3
    const averageDOMCompleteWithTags = (pagePerfWithThirdPartyTags1.DOMComplete + pagePerfWithThirdPartyTags2.DOMComplete + pagePerfWithThirdPartyTags3.DOMComplete) / 3
    const averageDOMCompleteWithoutTags = (pagePerfWithoutThirdPartyTags1.DOMComplete + pagePerfWithoutThirdPartyTags2.DOMComplete + pagePerfWithoutThirdPartyTags3.DOMComplete) / 3
    const averageDOMInteractiveWithTags = (pagePerfWithThirdPartyTags1.DOMInteractive + pagePerfWithThirdPartyTags2.DOMInteractive + pagePerfWithThirdPartyTags3.DOMInteractive) / 3
    const averageDOMInteractiveWithoutTags = (pagePerfWithoutThirdPartyTags1.DOMInteractive + pagePerfWithoutThirdPartyTags2.DOMInteractive + pagePerfWithoutThirdPartyTags3.DOMInteractive) / 3
    const averageDOMLoadingWithTags = (pagePerfWithThirdPartyTags1.DOMLoading + pagePerfWithThirdPartyTags2.DOMLoading + pagePerfWithThirdPartyTags3.DOMLoading) / 3
    const averageDOMLoadingWithoutTags = (pagePerfWithoutThirdPartyTags1.DOMLoading + pagePerfWithoutThirdPartyTags2.DOMLoading + pagePerfWithoutThirdPartyTags3.DOMLoading) / 3
    const averageFirstContentfulPaintWithTags = (pagePerfWithThirdPartyTags1.FirstContentfulPaint + pagePerfWithThirdPartyTags2.FirstContentfulPaint + pagePerfWithThirdPartyTags3.FirstContentfulPaint) / 3
    const averageFirstContentfulPaintWithoutTags = (pagePerfWithoutThirdPartyTags1.FirstContentfulPaint + pagePerfWithoutThirdPartyTags2.FirstContentfulPaint + pagePerfWithoutThirdPartyTags3.FirstContentfulPaint) / 3

    return {
      numExecutions: 3,
      ScriptDuration: {
        withTags: averageScriptDurationWithTags,
        withoutTags: averageScriptDurationWithoutTags,
        difference: averageScriptDurationWithTags - averageScriptDurationWithoutTags,
        percentFasterWithoutTags: `${(averageScriptDurationWithTags / (averageScriptDurationWithTags - averageScriptDurationWithoutTags)) * 100}%`,
      },
      TaskDuration: {
        withTags: averageTaskDurationWithTags,
        withoutTags: averageTaskDurationWithoutTags,
        difference: averageTaskDurationWithTags - averageTaskDurationWithoutTags,
        percentFasterWithoutTags: `${(averageTaskDurationWithTags / (averageTaskDurationWithTags - averageTaskDurationWithoutTags)) * 100}%`,
      },
      DOMComplete: {
        withTags: averageDOMCompleteWithTags,
        withoutTags: averageDOMCompleteWithoutTags,
        difference: averageDOMCompleteWithTags - averageDOMCompleteWithoutTags,
        percentFasterWithoutTags: `${(averageDOMCompleteWithTags / (averageDOMCompleteWithTags - averageDOMCompleteWithoutTags)) * 100}%`,
      },
      DOMInteractive: {
        withTags: averageDOMInteractiveWithTags,
        withoutTags: averageDOMInteractiveWithoutTags,
        difference: averageDOMInteractiveWithTags - averageDOMInteractiveWithoutTags,
        percentFasterWithoutTags: `${(averageDOMInteractiveWithTags / (averageDOMInteractiveWithTags - averageDOMInteractiveWithoutTags)) * 100}%`,
      },
      DOMLoading: {
        withTags: averageDOMLoadingWithTags,
        withoutTags: averageDOMLoadingWithoutTags,
        difference: averageDOMLoadingWithTags - averageDOMLoadingWithoutTags,
        percentFasterWithoutTags: `${(averageDOMLoadingWithTags / (averageDOMLoadingWithTags - averageDOMLoadingWithoutTags)) * 100}%`,
      },
      FirstContentfulPaint: {
        withTags: averageFirstContentfulPaintWithTags,
        withoutTags: averageFirstContentfulPaintWithoutTags,
        difference: averageFirstContentfulPaintWithTags - averageFirstContentfulPaintWithoutTags,
        percentFasterWithoutTags: `${(averageFirstContentfulPaintWithTags / (averageFirstContentfulPaintWithTags - averageFirstContentfulPaintWithoutTags)) * 100}%`,
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
        FirstContentfulPaint: performance.getEntriesByName('first-contentful-paint')?.at(0)?.startTime
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