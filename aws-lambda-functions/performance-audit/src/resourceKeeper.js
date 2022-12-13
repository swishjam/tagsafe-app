class ResourceKeeper {
  constructor(pageEventHandler) {
    this.pageEventHandler = pageEventHandler;
    this._requestsCached = [];
    this._requestsNotCached = [];
    this._resourcesBlocked = [];
    this._thirdPartyTagUrlsAllowed = [];
    
    this._resourcesWaitingToLoadSet = new Set();
    this._resourcesLoadedSet = new Set();
    this._resourcesFailedToLoadSet = new Set();

    this._injectedTagPromise = new Promise(resolve => this._injectedTagPromiseResolve = resolve);
    
    this._listenForResourceEvents();
  }

  requestsCached = () => this._requestsCached;
  requestsNotCached = () => this._requestsNotCached;
  resourcesBlocked = () => this._resourcesBlocked;
  resourcesWaitingToLoad = () => Array.from(this._resourcesWaitingToLoadSet);
  resourcesLoaded = () => Array.from(this._resourcesLoadedSet);
  resourcesFailedToLoad = () => Array.from(this._resourcesFailedToLoadSet);
  thirdPartyTagUrlsAllowed = () => this._thirdPartyTagUrlsAllowed;

  waitForInjectedTag = async () => {
    return await this._injectedTagPromise;
  }

  _listenForResourceEvents = () => {
    this.pageEventHandler.on('INJECTED_TAG_LOADED', () => this._injectedTagPromiseResolve());
    this.pageEventHandler.on('RESOURCE_BLOCKED', (resourceUrl, resourceType) => this._resourcesBlocked.push({ url: (resourceUrl || '').startsWith('data:image/') ? 'INLINE IMG' : resourceUrl, resource_type: resourceType }));
    this.pageEventHandler.on('REQUEST_CACHED', requestUrl => this._requestsCached.push((requestUrl || '').startsWith('data:image/') ? 'INLINE IMG' : requestUrl));
    this.pageEventHandler.on('REQUEST_NOT_CACHED', requestUrl => this._requestsNotCached.push((requestUrl || '').startsWith('data:image/') ? 'INLINE IMG' : requestUrl));
    this.pageEventHandler.on('EXPECT_RESOURCE_TO_LOAD', resourceUrl => this._resourcesWaitingToLoadSet.add(resourceUrl) );
    this.pageEventHandler.on('RESOURCE_FAILED_TO_LOAD', resourceUrl => {
      this._resourcesWaitingToLoadSet.delete(resourceUrl);
      this._resourcesFailedToLoadSet.add(resourceUrl);      
    });
    this.pageEventHandler.on('RESOURCE_LOADED', resourceUrl => {
      this._resourcesWaitingToLoadSet.delete(resourceUrl);
      this._resourcesLoadedSet.add(resourceUrl);
    });
    this.pageEventHandler.on('THIRD_PARTY_TAG_ALLOWED', url => this._thirdPartyTagUrlsAllowed.push(url) )
  }
}

module.exports = ResourceKeeper;