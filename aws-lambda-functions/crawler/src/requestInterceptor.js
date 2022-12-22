const fs = require('fs'),
        fetch = require('node-fetch');

class RequestInterceptor {
  constructor({ url, firstPartyUrlPatterns }) {
    this.url = url;
    this.firstPartyUrlPatterns = firstPartyUrlPatterns.concat([this._urlDomain()]);
    
    this.interceptHTMLRequest = process.env.INTERCEPT_HTML_REQUEST !== 'false'

    this.thirdPartyTags = {};
    this.firstPartyJsFiles = {};
    this.firstPartyJsBytes = 0;
    this.thirdPartyJsBytes = 0;
  }

  setupInterceptionForPage = async page => {
    console.log(`Setting request interception rules, considering ${this.firstPartyUrlPatterns.join(', ')} first party requests...`);
    await page.setRequestInterception(true);
    await this._setupMockInitialPageRequest();
    this._handleRequests(page);
  }

  _setupMockInitialPageRequest = async () => {
    if(this.interceptHTMLRequest) {
      try {
        console.log(`Setting up initial page request override, fetching initial page content from ${this.url}....`);
        const resp = await fetch(this.url, {
          headers: { 
            'TAGSAFE-REQUEST': 'true',
            'User-Agent': "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0"
          }
        });
        if(resp.status > 299) throw Error(`Unable to fetch HTML from ${this.url}, returned a status of ${resp.status}`);
        const pageHtml = await resp.text();
        this.pageHtmlContentsPath = `/tmp/${this.url.replace(/\/|\:|\./g, '_')}_${Date.now()}.html`;
        console.log(`Writing HTML of ${this.url} to ${this.pageHtmlContentsPath}`);
        fs.writeFileSync(this.pageHtmlContentsPath, pageHtml);
      } catch(err) {
        console.log(`Unable to override HTML from ${this.url}, going to use real request/responses...`);
        this.interceptHTMLRequest = false;
      }
    }
  }

  _handleRequests = page => {
    page.on('request', async request => {
      if(this.interceptHTMLRequest && page.url() === 'about:blank' && request.resourceType() === 'document') {
        console.log(`Overwriting ${request.url()} response with cached HTML from ${this.pageHtmlContentsPath}.`)
        request.respond({ body: fs.readFileSync(this.pageHtmlContentsPath) });
      } else {
        if(this._isThirdPartyJsRequest(request)) {
          const numBytes = await this._numJsBytes(request.url());
          this.thirdPartyJsBytes += numBytes;
          console.log(`Found third party tag: ${request.url()}, ${numBytes} bytes.`);
          this.thirdPartyTags[request.url()] = { bytes: numBytes };
        } else if(this._isFirstPartyJsRequest(request)) {
          const numBytes = await this._numJsBytes(request.url());
          this.firstPartyJsFiles[request.url()] = { bytes: numBytes };
          this.firstPartyJsBytes += numBytes;
          console.log(`First party tag: ${request.url()}, ${numBytes} bytes.`);
        }
        await request.continue();
      }
    });
  }

  _numJsBytes = async url => {
    const resp = await fetch(url, {
      headers: { 
        'TAGSAFE-REQUEST': 'true',
        'User-Agent': "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0"
      }
    });
    const bytes = Buffer.byteLength(await resp.text())
    return bytes;
  }

  _isThirdPartyJsRequest = request => {
    return request.resourceType() === 'script' && !this._isFirstPartyJsRequest(request);
  }

  _isFirstPartyJsRequest = request => {
    // return request.resourceType() === 'script' && !!this.firstPartyUrlPatterns.find(urlPattern => request.url().includes(urlPattern));
    return request.resourceType() === 'script' && !!this.firstPartyUrlPatterns.find(urlPattern => new URL(request.url()).hostname.includes(urlPattern));
  }

  _urlDomain = () => {
    if(process.env.CONSIDER_SUB_DOMAINS_FIRST_PARTY === 'true') {
      let splitHostname = new URL(this.url).hostname.split('.');
      splitHostname.shift();
      return splitHostname.join('.');
    } else {
      return new URL(this.url).hostname;
    }
  }
}

module.exports = RequestInterceptor;