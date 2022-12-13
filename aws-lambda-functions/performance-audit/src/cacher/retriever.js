const s3 = require('../s3'),
      fs = require('fs');

class CacheRetriever {
  constructor(cachedResponsesS3Key, returnCachedResponsesImmediately) {
    this.cachedResponsesS3Key = cachedResponsesS3Key;
    this.returnCachedResponsesImmediately = returnCachedResponsesImmediately;
  }

  setupCache = async () => {
    if(this.cachedResponsesS3Key) {
      if(process.env.CACHED_RESPONSES_FILE_IS_LOCAL === 'true') {
        this.cachedResponses = this.cachedResponses || JSON.parse(fs.readFileSync(this.cachedResponsesS3Key));
      } else {
        this.cachedResponses = this.cachedResponses || JSON.parse(await s3.getObject(this.cachedResponsesS3Key));
      }
    } else {
      this.cachedResponses = {};
      console.log(`Cached Responses S3 URL was not provided to Page Manipulator, continuing without cached data.`);
    }
  }

  hasCache = () => {
    return Object.keys(this.cachedResponses).length > 0;
  }

  hasCacheForRequestUrl = url => {
    return typeof this.cachedResponses[url] !== 'undefined';
  }

  returnCachedRequest = async request => {
    const cacheData = this.cachedResponses[request.url()];
    if(cacheData['data'] || cacheData['bufferedData']) {
      console.log(`Overrode ${request.url()} response with cached data.`);
      if(!this.returnCachedResponsesImmediately) {
        const sleepMs = cacheData['responseTimeMs'] || 0;
        console.log(`Returning cached response after sleeping ${sleepMs} ms.`)
        await this._sleep(sleepMs);
      }
      return await request.respond({ 
        headers: cacheData['headers'],
        status: cacheData['status'],
        body: cacheData['data'] || Buffer.from(cacheData['bufferedData']) 
      })
    } else {
      console.log(`No cached data for ${request.url()}, continuing with real request...`);
      await request.continue();
    }
  }

  _sleep = async ms => {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = CacheRetriever;