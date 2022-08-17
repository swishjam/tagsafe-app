const MainThreadAnalyzer = require('./mainThreadAnalyzer');

module.exports = class PerformanceMeasurer {
  constructor({ page, traceFilePath, tagUrl }) {
    this.page = page;
    this.traceFilePath = traceFilePath;
    this.tagUrl = tagUrl;
  }

  async measurePerformanceOfTag() {
    const { domInteractive, domComplete } = await this.page.evaluate(() => {
      const domInteractive = performance.timing.domInteractive - performance.timing.navigationStart;
      const domComplete = performance.timing.domComplete - performance.timing.navigationStart;
      return { domInteractive, domComplete };
    });
    const mainThreadExecutions = new MainThreadAnalyzer({ 
      traceFilePath: this.traceFilePath, 
      urlPattern: this.tagUrl,
      domInteractive,
      domComplete
    }).gatherMainThreadExecutionMetrics();
    console.log(mainThreadExecutions);
    console.log({ domInteractive, domComplete });
    return [];
  }
}