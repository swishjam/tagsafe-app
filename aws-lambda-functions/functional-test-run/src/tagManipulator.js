class TagManipulator {
  constructor({ firstPartyUrl, thirdPartyTagUrlsAndRulesToInject, thirdPartyTagUrlPatternsToAllow }) {
    this.firstPartyUrl = firstPartyUrl;
    this.thirdPartyTagUrlsAndRulesToInject = thirdPartyTagUrlsAndRulesToInject;
    this.thirdPartyTagUrlPatternsToAllow = thirdPartyTagUrlPatternsToAllow;

    this.thirdPartyTagsBlocked = [];
    this.thirdPartyTagsAllowed = [];
    this.requestsAllowed = [];
  }

  setUpTagManipulationForPage = async page => {
    await this._setTagInjectionRulesForPage(page);
    await this._setRequestInterceptorRulesForPage(page);
  }

  _setTagInjectionRulesForPage = async page => {
    console.log('Setting tag injection rules...');
    await page.evaluateOnNewDocument(tagUrlsAndRulesToInject => {
      if(window !== window.parent) return;
      tagUrlsAndRulesToInject.forEach(urlAndRule => {
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
        if(document.head) {
          document.head.appendChild(script);
          console.log(`Added ${urlAndRule.url} to DOM after ${counter} ms`);
        } else {
          let counter = 0;
          let waitForHeadInterval = setInterval(() => {
            counter += 1;
            if(document.head) {
              document.head.appendChild(script);
              console.log(`Added ${urlAndRule.url} to DOM after ${counter} ms`);
              clearInterval(waitForHeadInterval);
            }
          }, 1);
        }
      })
    }, this.thirdPartyTagUrlsAndRulesToInject);
  }

  _setRequestInterceptorRulesForPage = async page => {
    console.log('Setting request interception...');
    page.setRequestInterception(true);
    page.on('request', async request => {
      if(this._shouldAbortRequest(request)) {
        // console.log(`Aborting request to: ${request.url()}`);
        await request.abort();
        this.thirdPartyTagsBlocked.push(request.url());
      } else {
        console.log(`Allowing request to ${request.url()}`);
        this.requestsAllowed.push(request.url());
        await request.continue();
        if(request.resourceType() === 'script' && this._isThirdPartyRequestUrl(request.url())) {
          // console.log(`Allowing third party request to: ${request.url()}`);
          this.thirdPartyTagsAllowed.push(request.url());
        }
      }
    });
  }

  _shouldAbortRequest = request => {
    return request.resourceType() === 'script' && this._isThirdPartyRequestUrl(request.url()) && !this._isAllowedThirdPartyRequestUrl(request.url());
  }

  _isAllowedThirdPartyRequestUrl = requestUrl => {
    return !!this.thirdPartyTagUrlPatternsToAllow.find(urlPattern => requestUrl.includes(urlPattern))
  }

  _isThirdPartyRequestUrl = requestUrl => {
    const requestHost = new URL(requestUrl).hostname;
    const pageHost = new URL(this.firstPartyUrl).hostname;
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

module.exports = TagManipulator;