class RequestInterceptor{
  constructor({ 
    page, 
    shouldGenerateCache = false,
    pageManipulator,
    thirdPartyTagDetector,
    cacheRetriever, 
    pageEventHandler,
    blockImageRequests
  }) {
    this.page = page;
    this.shouldGenerateCache = shouldGenerateCache;
    this.pageManipulator = pageManipulator;
    this.cacheRetriever = cacheRetriever;
    this.pageEventHandler = pageEventHandler;
    this.thirdPartyTagDetector = thirdPartyTagDetector;
    this.blockImageRequests = blockImageRequests;

    this.scrubbedBase64Image = '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';

    this.inflightRequests = new Set();
    this.completedRequests = [];
  }

  setupRequestInterceptionForManipulatedAndCachedRequests = async () => {
    await this.cacheRetriever.setupCache();
    await this.pageManipulator.manipulateAuditUrlPageContent();
    await this.page.setRequestInterception(true);
    this._interceptRequests();
  }

  beginCacheGeneration = async () => {
    this.cachedResponseData = {};
    await this.pageManipulator.manipulateAuditUrlPageContent();
    await this.page.setRequestInterception(true);
    await this._cacheAllRequestAndResponse();
  }

  _cacheAllRequestAndResponse = async () => {
    this.page.on('request', async request => {
      this.cachedResponseData[request.url()] = { requestTs: Date.now() };
      const isInitialPageRequest = request.resourceType() === 'document' && this.page.url() === 'about:blank';
      if(isInitialPageRequest && this.pageManipulator.shouldOverrideInitialHTMLRequest()) {
        this.pageManipulator.overrideInitialHTMLRequest(request);
      } else {
        await request.continue();
      }
    })
    this.page.on('response', async response => {
      try {
        const responseTs = Date.now();
        const cachedResponse = this.cachedResponseData[response.url()];
        if(!cachedResponse) throw new Error(`Received response for ${response.url()} with no corresponding request key in cachedResponses`);
    
        const resourceType = response.request().resourceType();
        const useBufferedData = ['image', 'media', 'font'].includes(resourceType);
        const respData = useBufferedData ? await response.buffer() : await response.text();
    
        cachedResponse['resourceType'] = resourceType;
        cachedResponse['headers'] = response.headers();
        cachedResponse['status'] = response.status();
        cachedResponse['responseTs'] = responseTs;
        cachedResponse['responseTimeMs'] = responseTs - cachedResponse['requestTs'];
        cachedResponse[useBufferedData ? 'bufferedData' : 'data'] = respData;
        console.log(`Cached ${response.url()} (${cachedResponse['responseTimeMs']} ms response time)`)
      } catch(err) {
        console.log(`Error trying to cache ${response.url()} response: ${err}`);
      }
    })
  }

  _interceptRequests = async () => {
    this.page.on('request', async req => await this._handleRequest(req));
    this.page.on('response', resp => this._requestCompleted(resp.url()) );
    this.page.on('requestfailed', async req => await this.pageEventHandler.emit('FAILED_NETWORK_REQUEST', req.url()));
  }

  _handleRequest = async request => {
    this._newRequest(request.url());
    const isInitialPageRequest = request.resourceType() === 'document' && this.page.url() === 'about:blank';
    if(isInitialPageRequest && this.pageManipulator.shouldOverrideInitialHTMLRequest()) {
      this.pageManipulator.overrideInitialHTMLRequest(request);
      this.pageEventHandler.emit('REQUEST_CACHED', request.url());
      // this._requestCompleted(request.url());
    } else if(this.blockImageRequests && request.resourceType() === 'image') {
      if(process.env.USE_PLACEHOLDER_BACKGROUND_IMAGES === 'true') {
        request.respond({ body: Buffer.from(this.scrubbedBase64Image, 'base64'), status: 200 });
      } else {
        request.respond({ body: '#', status: 200 });
        // await req.abort();
      }
      this.pageEventHandler.emit('RESOURCE_BLOCKED', request.url(), 'img');
      // this._requestCompleted(request.url());
    } else if(request.resourceType() === 'script' && this.thirdPartyTagDetector.isThirdPartyUrl(request.url())) {
      if(this.thirdPartyTagDetector.isAllowedThirdPartyUrl(request.url())) {
        await request.continue();
        this.pageEventHandler.emit('THIRD_PARTY_TAG_ALLOWED', request.url());
      } else {
        await request.abort();
        this.pageEventHandler.emit('RESOURCE_BLOCKED', request.url(), 'script');
      }
    } else {
      await this._tryToReturnCachedRequest(request);
    }
  }

  _tryToReturnCachedRequest = async request => {
    const hasCache = this.cacheRetriever.hasCacheForRequestUrl(request.url());
    if(hasCache) {
      await this.cacheRetriever.returnCachedRequest(request);
      this.pageEventHandler.emit('REQUEST_CACHED', request.url());
      // this._requestCompleted(request.url());
    } else {
      await request.continue();
      this.pageEventHandler.emit('REQUEST_NOT_CACHED', request.url());
      // this._requestCompleted(request.url());
    }
  }

  _newRequest = url => {
    this.inflightRequests.add(url);
  }

  _requestCompleted = url => {
    this.inflightRequests.delete(url);
    this.completedRequests.push(url);
  }
}

module.exports = RequestInterceptor;