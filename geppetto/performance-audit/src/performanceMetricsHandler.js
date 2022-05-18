class PerformanceMetricsHandler {
  constructor({ page, pageEventHandler, includePageLoadResources }) {
    this.page = page;
    this.pageEventHandler = pageEventHandler;
    this.includePageLoadResources = includePageLoadResources;

    this._performanceResults = {};
  }

  performanceResults = () => this._performanceResults;

  listenForPerformanceMetricsPageEvents = async () => {
    await this.page.exposeFunction('getLCP', callback => getLCP(callback));
    await this.page.exposeFunction('getFID', callback => getFID(callback));
    await this.page.exposeFunction('getCLS', callback => getCLS(callback));

    this._performanceResults['long_running_tasks'] = [];
    this.pageEventHandler.on('LONG_RUNNING_TASK', data => this._performanceResults['long_running_tasks'].push(JSON.parse(data)));
    this.pageEventHandler.on('WEB_VITALS_LCP', data => this._performanceResults['LCP'] = data);
    this.pageEventHandler.on('WEB_VITALS_FID', data => this._performanceResults['FID'] = data);
    this.pageEventHandler.on('WEB_VITALS_CLS', data => this._performanceResults['CLS'] = data);
  }

  gatherPerformanceResults = async () => {
    console.log('Gathering performance metrics...');
    return await this._calculatePerformanceMetrics();
  }

  _calculatePerformanceMetrics = async () => {
    const puppeteerMetrics = await this.page.metrics();
    const domPerformanceTimings = await this._getDomTimingsFromPerformanceApi();
    const combinedMetrics = Object.assign({}, puppeteerMetrics, domPerformanceTimings);

    this._pushMetricsIntoPerformanceResults(combinedMetrics);
    await this._pushPageLoadResourcesIntoPerformanceResultsIfNecessary();

    console.log('Gathered performance results!');
    return this._performanceResults;
  }

  _getDomTimingsFromPerformanceApi = async () => {
    return JSON.parse(await this.page.evaluate(() =>
      JSON.stringify({
        FirstContentfulPaint: performance.getEntriesByName('first-contentful-paint')[0].startTime,
        DOMComplete: performance.getEntriesByType('navigation')[0].domComplete,
        DOMInteractive: performance.getEntriesByType('navigation')[0].domInteractive,
        DOMContentLoaded: performance.getEntriesByType('navigation')[0].domContentLoadedEventEnd,
        Load: performance.getEntriesByType('navigation')[0].loadEventEnd
      })
    ));
  }

  _pushPageLoadResourcesIntoPerformanceResultsIfNecessary = async () => {
    if(this.includePageLoadResources) {
      console.log('Including page load resources...');
      const resources = await this.page.evaluate(() => JSON.stringify(performance.getEntries()));
      this._performanceResults['page_load_resources'] = JSON.parse(resources);
    } else {
      console.log('Not including page load resources...');
      this._performanceResults['page_load_resources'] = [];
    }
  }

  _pushMetricsIntoPerformanceResults = metrics => {
    const metricsToCapture = ['TaskDuration', 'ScriptDuration', 'LayoutDuration', 'FirstContentfulPaint', 'DOMInteractive', 'DOMComplete', 'DOMContentLoaded', 'Load'];
    // TODO: all times are in monotonic time?
    const metricsInSeconds = ['TaskDuration', 'ScriptDuration', 'LayoutDuration'];
    metricsToCapture.forEach(metric => {
      if(metricsInSeconds.includes(metric)) metrics[metric] = metrics[metric]*1000;
      this._performanceResults[metric] = metrics[metric];
    })
  }
}

module.exports = PerformanceMetricsHandler;