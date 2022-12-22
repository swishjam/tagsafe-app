import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [
    'domContentLoaded', 'pageLoaded', 'thirdPartyRequestsContainer', 'totalNetworkTime', 
    'openIcon', 'numTagsOptimized'
  ];

  connect() {
    this._beginTicker();
    this._setDOMContentLoadedListener();
    this._setPageLoadListener();
  }

  toggleThirdPartyRequestsContainer() {
    const isMinimzed = this.thirdPartyRequestsContainerTarget.classList.contains('minimized');
    if (isMinimzed) {
      this.thirdPartyRequestsContainerTarget.classList.remove('minimized');
      this.openIconTarget.classList.remove('minimized')
    } else {
      this.thirdPartyRequestsContainerTarget.classList.add('minimized');
      this.openIconTarget.classList.add('minimized')
    }
  }

  _beginTicker() {
    const scope = this;

    let ticker = 0;
    this.domContentLoadedTarget.innerText = Date.now() - (window.performance.timing.navigationStart || Date.now());
    this.pageLoadedTarget.innerText = Date.now() - (window.performance.timing.navigationStart || Date.now());
    
    this.domContentLoadedTickerInterval = setInterval(function () {
      ticker += 50;
      scope.domContentLoadedTarget.innerText = ticker;
    }, 50);

    this.pageLoadedTickerInterval = setInterval(function () {
      ticker += 50;
      scope.pageLoadedTarget.innerText = ticker;
    }, 50);

    this.pageLoadDoubleCheckInterval = setInterval(function() {
      if(document.readyState === 'complete') {
        scope._onPageLoad();
      }
    }, 250)
  }

  _setDOMContentLoadedListener() {
    if(document.readyState !== 'loading') {
      this._onDOMComplete();
    } else {
      document.addEventListener('DOMContentLoaded', this._onDOMComplete);
    }
  }

  _setPageLoadListener() {
    if(document.readyState === 'complete') {
      this._onPageLoad();
    } else {
      document.addEventListener('load', this._onPageLoad);
    }
  }

  _onDOMComplete() {
    clearInterval(this.domContentLoadedTickerInterval);
    this.domContentLoadedTarget.innerText = window.performance.timing.domContentLoadedEventStart - window.performance.timing.navigationStart;
  }

  _onPageLoad() {
    clearInterval(this.pageLoadedTickerInterval);
    clearInterval(this.pageLoadDoubleCheckInterval);
    this.pageLoadedTarget.innerText = window.performance.timing.loadEventStart - window.performance.timing.navigationStart;
    this._measureNetworkTimes();
  }

  _measureNetworkTimes() {
    const resources = window.performance.getEntriesByType('resource');
    let total = 0;
    let numTagsOptimized = 0;

    for (let i = 0; i < resources.length; i++) {
      const resource = resources[i];
      if (resource.initiatorType === 'script' && this._isThirdPartyUrl(resource.name)) {
        // times[resource.name] = resource.duration;
        const el = document.createElement('span');
        el.classList.add('d-block');
        el.innerText = resource.name + ': ' + resource.duration + ' ms';
        this.thirdPartyRequestsContainerTarget.appendChild(el);
        total += resource.duration;
        if(
          (resource.name.includes('cdn-collin-dev.tagsafe.io') || resource.name.includes('cdn.tagsafe.io')) &&
          !resource.name.includes('instrumentation')
        ) {
          numTagsOptimized += 1;
        }
      }
    }
    this.totalNetworkTimeTarget.innerText = total.toFixed(2);
    this.numTagsOptimizedTarget.innerText = numTagsOptimized;
  }

  _isThirdPartyUrl(url) {
    return this._domainForUrl(url) !== this._domainForUrl(window.location.href);
  }

  _domainForUrl(url) {
    const splitHost = new URL(url).hostname.split('.');
    return [splitHost[splitHost.length - 2], splitHost[splitHost.length - 1]].join('.')
  }

  _formatMs(ms) {
    return ms < 1_000 ? ms + ' ms' : ms / 1_000 + ' seconds'
  }
}