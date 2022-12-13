const s3 = require('../s3.js'),
        NETWORK_PRESETS = require('../networkPresets');

class CacheGenerator {
  constructor({ 
    page, 
    pageUrl, 
    pageManipulator,
    requestInterceptor,
    thirdPartyTagDetector,
    validityChecker,
    scrollPage,
    networkToEmulate = 'Regular4G'
  }) {
    this.page = page;
    this.pageUrl = pageUrl;
    this.pageManipulator = pageManipulator;
    this.requestInterceptor = requestInterceptor;
    this.thirdPartyTagDetector = thirdPartyTagDetector;
    this.validityChecker = validityChecker;
    
    this.networkToEmulate = networkToEmulate;
    this.scrollPage = scrollPage;
  }

  generateCache = async () => {
    await this.page.emulateNetworkConditions(NETWORK_PRESETS[this.networkToEmulate]);
    await this.requestInterceptor.beginCacheGeneration();
    await this.page.goto(this.pageUrl, { waitUntil: 'domcontentloaded' });
    await this._scrollToBottomOfPageIfNecessary();
    await this.validityChecker.ensureAuditIsValid();
    await this._uploadCachedResponsesToS3();
  }

  _scrollToBottomOfPageIfNecessary = async () => {
    if(this.scrollPage) {
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

  _uploadCachedResponsesToS3 = async () => {
    this.cachedResponsesS3Location = await s3.uploadToS3({ 
      Body: JSON.stringify(this.requestInterceptor.cachedResponseData), 
      Key: `${this.pageUrl.replace(/\.|\/|\\|\:/g, '_')}-cached-responses-${Date.now()}-${parseInt(Math.random() * 1_000_000)}.json` 
    })
  }
}

module.exports = CacheGenerator;