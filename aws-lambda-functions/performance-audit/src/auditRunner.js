const NETWORK_PRESETS = require('./networkPresets');

const DEFAULT_OPTIONS = {
  includePageLoadResources: true,
  navigationTimeoutMs: 0,
  navigationWaitUntil: 'networkidle2',
  networkToEmulate: 'Regular4G',
  scrollPage: true,
  userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36'
};

class AuditRunner {
  constructor({ 
    page, 
    urlToAudit, 
    tracer,
    requestInterceptor, 
    screenRecorder, 
    performanceMetricsHandler,
    validityChecker, 
    logger, 
    options = {}
  }) {
    this.page = page;
    this.urlToAudit = urlToAudit
    this.tracer = tracer;
    this.requestInterceptor = requestInterceptor;
    this.screenRecorder = screenRecorder;
    this.performanceMetricsHandler = performanceMetricsHandler;
    this.validityChecker = validityChecker;
    this.logger = logger;
    this.options = Object.assign({}, DEFAULT_OPTIONS, options);    
  }
  
  async runPerformanceAudit() {
    let startTime = Date.now();
    await this._setPageConfig();
    await this.performanceMetricsHandler.listenForPerformanceMetricsPageEvents();
    await this.requestInterceptor.setupRequestInterceptionForManipulatedAndCachedRequests();
    await this.screenRecorder.startRecordingIfNecessary();
    await this.tracer.startTracingIfNecessary();
    await this._navigateToUrl();
    await this._scrollToBottomOfPageIfNecessary();
    await this.validityChecker.ensureAuditIsValid();
    await this.tracer.stopTracing();
    await this.screenRecorder.tryToStopRecordingAndUploadToS3IfNecessary();
    await this.performanceMetricsHandler.gatherPerformanceResults();
    console.log(`====== Audit completed in ${(Date.now() - startTime)/1000} seconds. =======`);
  }

  _setPageConfig = async () => {
    console.log(`Emulating ${this.options.networkToEmulate} network conditions and user agent of ${this.options.userAgent}`);
    await this.page.emulateNetworkConditions(NETWORK_PRESETS[this.options.networkToEmulate]);
    await this.page.setUserAgent(this.options.userAgent);
  }

  _navigateToUrl = async () => {
    let start = new Date();
    console.log(`Navigating to ${this.urlToAudit}, waiting until domcontentloaded with a timeout of ${this.options.navigationTimeoutMs} ms.`);
    await this.page.goto(this.urlToAudit, { 
      // waitUntil: this.options.navigationWaitUntil,
      // waitUntil: ['domcontentloaded', 'networkidle2'],
      waitUntil: 'domcontentloaded',
      timeout: this.options.navigationTimeoutMs
    });
    console.log(`Reached ${this.urlToAudit} in ${new Date() - start} ms`);
  }

  _scrollToBottomOfPageIfNecessary = async () => {
    if(this.options.scrollPage) {
      console.log('Scrolling to the bottom of the page...');
      await this.page.evaluate(async () => {
        await new Promise(resolve => {
          var totalHeight = 0;
          var distance = 100;
          var timer = setInterval(() => {
            var scrollHeight = document.body.scrollHeight;
            window.scrollBy(0, distance);
            totalHeight += distance;
  
            if(totalHeight >= scrollHeight){
              clearInterval(timer);
              resolve();
            }
          }, 100);
        });
      });
    }
  }
}

module.exports = AuditRunner;