const s3 = require('./s3');

class PageManipulator {
  constructor({ initialHtmlContentS3Key, thirdPartyTagUrlsAndRulesToInject, thirdPartyTagUrlPatternsToAllow }) {
    this.initialHtmlContentS3Key = initialHtmlContentS3Key;
    this.thirdPartyTagUrlPatternsToAllow = thirdPartyTagUrlPatternsToAllow;
    this.thirdPartyTagUrlsAndRulesToInject = thirdPartyTagUrlsAndRulesToInject;

    this.dontInterceptHtmlRequest = process.env.DONT_INTERCEPT_HTML_REQUESTS === 'true';

    this.thirdPartyTagsBlocked = [];
    this.thirdPartyTagsAllowed = [];
    this.firstPartyJavascriptRequests = [];
  }

  preparePage = async page => {
    await this._setTagInjectionRules(page);
    await this._setRequestInterceptorRules(page);
  }

  _setTagInjectionRules = async page => {
    console.log('Beginning _setTagInjectionRules...')
    if(this.thirdPartyTagUrlsAndRulesToInject.length > 0) {
      await page.evaluateOnNewDocument(tagUrlsAndRulesToInject => {
        tagUrlsAndRulesToInject.forEach(urlAndRule => {
          try {
            if(self !== top) return;
            let script = document.createElement('script');
            script.src = urlAndRule.url;
            switch(urlAndRule.load_type) {
              case 'async':
                script.setAttribute('async', 'true')
                break;
              case 'defer':
                script.setAttribute('defer', 'true')
                break;
              default:
                break;
            }
            script.addEventListener('load', function() { console.log(`TAGSAFE_LOG::LOG::tagsafe injected tag ${script.src} has loaded`); window.tagsafeInjectedTagLoaded = function() {}; })
            script.addEventListener('error', function() { console.error(`TAGSAFE_LOG::ERROR::Failed to load Tagsafe injected tag: ${script.src}`) })
            let counter = 0;
            let waitForHeadInterval = setInterval(() => {
              counter += 1;
              if(document.head) {
                document.head.appendChild(script);
                clearInterval(waitForHeadInterval);
                console.log(`TAGSAFE_LOG::LOG::Added ${script.src} to ${window.location.href} DOM after ${counter} ms`);
              }
            }, 1);
          } catch(e) { console.error(`TAGSAFE_LOG::LOG::error injecting ${urlAndRule.url}: ${e.message}`) }
        })
      }, this.thirdPartyTagUrlsAndRulesToInject);
    }
  }

  _setRequestInterceptorRules = async page => {
    console.log('Beginning _setRequestInterceptorRules...');
    await page.setRequestInterception(true);
    page.on('request', async request => {
      if(!this.dontInterceptHtmlRequest && page.url() === 'about:blank' && request.resourceType() === 'document') {
        console.log(`Overwriting ${request.url()} with cache paged content with S3 content: ${this.initialHtmlContentS3Key}`);
        request.respond({ body: await s3.getObject(this.initialHtmlContentS3Key) })
      } else if(this._shouldAbortRequest(page.url(), request)) {
        console.log(`Aborting request to: ${request.url()}`);
        await request.abort();
        this.thirdPartyTagsBlocked.push(request.url());
      } else {
        await request.continue();
        if(request.resourceType() === 'script' ) {
          if(this._isThirdPartyRequestUrl(page.url(), request.url())) {
            console.log(`Allowing third party request to: ${request.url()}`);
            this.thirdPartyTagsAllowed.push(request.url());
          } else {
            console.log(`Allowing JS request to: ${request.url()}`);
            this.firstPartyJavascriptRequests.push(request.url())
          }
        }
      }
    });
  }

  _shouldAbortRequest = (pageUrl, request) => {
    return request.resourceType() === 'script' && this._isThirdPartyRequestUrl(pageUrl, request.url()) && !this._isAllowedThirdPartyRequestUrl(request.url());
  }

  _isAllowedThirdPartyRequestUrl = requestUrl => {
    return !!this.thirdPartyTagUrlPatternsToAllow.find(urlPattern => requestUrl.includes(urlPattern))
  }

  _isThirdPartyRequestUrl = (pageUrl, requestUrl) => {
    const requestHost = new URL(requestUrl).hostname;
    const pageHost = new URL(pageUrl).hostname;
    if(process.env.TREAT_SUBDOMAINS_AS_FIRST_PARTY_REQUESTS === 'false') {
      return requestHost !== pageHost;
    } else {
      const splitRequestHost = requestHost.split('.');
      const splitPageHost = pageHost.split('.');
      splitRequestHost.shift();
      splitPageHost.shift();
      return splitRequestHost.join('') !== splitPageHost.join('');
    }
  }
}

module.exports = PageManipulator;