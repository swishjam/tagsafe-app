const cheerio = require('cheerio'),
        fetch = require('node-fetch'),
        fs = require('fs');

class PageManipulator {
  constructor({
    page,
    pageUrl, 
    cacheRetriever,
    imageScrubber,
    thirdPartyTagScrubber,
    tagInjector,
    monkeyPatcher,
    overrideInitialHTMLRequestWithManipulatedPage
  }) {
    this.page = page;
    this.pageUrl = pageUrl;
    this.cacheRetriever = cacheRetriever;
    this.imageScrubber = imageScrubber;
    this.thirdPartyTagScrubber = thirdPartyTagScrubber;
    this.tagInjector = tagInjector;
    this.monkeyPatcher = monkeyPatcher;
    this.overrideInitialHTMLRequestWithManipulatedPage = overrideInitialHTMLRequestWithManipulatedPage;
  }

  overrideInitialHTMLRequest = request => {
    console.log(`Overriding ${request.url()} with manipulated HTML content.`);
    request.respond({ 
      body: this._overriddenPageHTML(), 
      status: 200 
    });
    this._clearOverriddenPage();
  }

  shouldOverrideInitialHTMLRequest = () => this.overrideInitialHTMLRequestWithManipulatedPage

  manipulateAuditUrlPageContent = async () => {
    if(this.shouldOverrideInitialHTMLRequest()) {
      await this._fetchAndManipulateAndStorePageHTML();
    } else {
      await this._injectMonkeyPatchScriptsOnNewDocument();
    }
  }

  _fetchAndManipulateAndStorePageHTML = async () => {
    console.log(`PageManipulator Fetching content from ${this.pageUrl} and manipulating the HTML to setup audit...`);
    const pageHTML = await this._fetchPageHTML();
    const cheerioDOM = cheerio.load(pageHTML);
    
    this.thirdPartyTagScrubber.scrubThirdPartyTagsFromCheerioDOM(cheerioDOM);
    this.imageScrubber.scrubImagesFromCheerioDOMIfNecessary(cheerioDOM);
    // this.resourceInliner.inlineResourcesInCheerioDOMIfNecessary(cheerioDOM)

    await this.tagInjector.injectScriptTagsIntoCheerioDOM(cheerioDOM);
    this.monkeyPatcher.addMonkeyPatchScriptToCheerioDOM(cheerioDOM);
    
    this.overridenPageLocalPath = `/tmp/manipulated-${this.pageUrl.replace(/[-|\.|\:|/|\?]/g, '_')}-${new Date().getTime()}.html`;
    fs.writeFileSync(this.overridenPageLocalPath, cheerioDOM.html(), err => { if(err) throw Error(err) });
    console.log(`Manipulated page\'s HTML and wrote to local file ${this.overridenPageLocalPath}`);
  }

  _injectMonkeyPatchScriptsOnNewDocument = async () => {
    console.log(`PageManipulator Setting up injecting tags on new document in order to run audit: ${JSON.stringify(this.tagInjector.tagsAndRulesToInject)}...`);
    if(this.tagInjector.tagsAndRulesToInject.length > 0) {
      await this.page.evaluateOnNewDocument(tagUrlsAndRulesToInject => {
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
            script.addEventListener('load', function() { 
              console.log(`TAGSAFE_LOG_EVENT::LOG::tagsafe injected tag ${script.src} has loaded`); 
              console.log(`TAGSAFE_LOG_EVENT::INJECTED_TAG_LOADED::${script.src}`);
              window.tagsafeInjectedTagLoaded = function() { console.log('stubbed') }; 
            })
            script.addEventListener('error', function() { console.error(`TAGSAFE_LOG_EVENT::INJECTED_TAG_ERROR::${script.src}`) })
            let counter = 0;
            let waitForHeadInterval = setInterval(() => {
              counter += 1;
              if(document.head) {
                document.head.appendChild(script);
                clearInterval(waitForHeadInterval);
                console.log(`TAGSAFE_LOG_EVENT::LOG::Added ${script.src} to ${window.location.href} DOM after ${counter} ms`);
              }
            }, 1);
          } catch(e) { console.error(`TAGSAFE_LOG_EVENT::LOG::error injecting ${urlAndRule.url}: ${e.message}`) }
        })
      }, this.tagInjector.tagsAndRulesToInject);
    }
  }

  _overriddenPageHTML = () => {
    if(!this.overridenPageLocalPath) throw Error(`PageManipulator overriddenPageBody is null`);
    return fs.readFileSync(this.overridenPageLocalPath)
  }

  _clearOverriddenPage = () => {
    if(this.overridenPageLocalPath) {
      fs.unlinkSync(this.overridenPageLocalPath);
      this.overridenPageLocalPath = null;
    }
  }

  _fetchPageHTML = async () => {
    const cachedResponse = this.cacheRetriever && this.cacheRetriever.cachedResponses[this.pageUrl];
    if(cachedResponse) {
      console.log(`Using cached response data for ${this.pageUrl} HTML content manipulation...`);
      return cachedResponse['data'];
    } else {
      console.log(`No cached data for ${this.pageUrl} HTML content, re-fetching before manipulating....`);
      const response = await fetch(this.pageUrl, {
        // redirect: 'manual',
        headers: {
          'TAGSAFE-REQUEST': 'true',
          'User-Agent': "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0"
        }
      });
      if(response.status > 399) {
        throw Error(`${this.pageUrl} resulted in a ${response.status} response.`);
      }
      // this.pageResponseHeaders = response.headers.raw();
      // this.pageResponseStatus = response.status;
      return await response.text();
    }
  }
}

module.exports = PageManipulator;