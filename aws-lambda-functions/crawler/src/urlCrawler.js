const chromium = require('chrome-aws-lambda'),
        // puppeteer = require('puppeteer-extra'),
        fs = require('fs');

// if(process.env.NODE_ENV === 'local') {
  // const URL = require('url');
// }

require('dotenv').config();
// const StealthPlugin = require('puppeteer-extra-plugin-stealth');
// puppeteer.use(StealthPlugin());

class URLCrawler {
  constructor({ url, requestInterceptor, options = {} }) {
    this.url = url;
    this.requestInterceptor = requestInterceptor;
    this.pageWaitUntil = options['puppeteerPageWaitUntil'];
    this.timeoutMs = options['puppeteerPageTimeoutMs'];

    this.includeTagLoadTypes = process.env.INCLUDE_TAG_LOAD_TYPES === 'true';
    this.navigationFullyCompleted = false;
    this.haultedNavigationBeforeReachingDomComplete = false;
    this.throwErrorIfPageDoesntReachDomComplete = false;
    this.navigationMsToHaultExecutionAndReturnResults = options['navigationMsToHaultExecutionAndReturnResults'] || 60_000;
  }

  crawlForThirdPartyTags = async () => {
    await this._launchPuppeteer();
    await this.requestInterceptor.setupInterceptionForPage(this.page);
    await Promise.race([
      this._navigateToUrl(),
      this._setDomCompletTimer()
    ]);
    await this._getTagsLoadTypes();
    await this.killBrowser();
  };

  killBrowser = async () => {
    console.log('killing browser...');
    if(this.requestInterceptor.pageHtmlContentsPath) fs.unlinkSync(this.requestInterceptor.pageHtmlContentsPath);
    if(this.page) await this.page.close();
    if(this.browser) await this.browser.close();
  }

  _launchPuppeteer = async () => {
    const executablePath = process.env.CHROMIUM_EXECUTABLE || await chromium.executablePath;
    console.log(`launching puppeteer to executable path ${executablePath}...`);
    this.browser = await chromium.puppeteer.launch({
      args: chromium.args,
      defaultViewport: chromium.defaultViewport,
      executablePath: executablePath,
      // headless: true
    });
    await this.browser.userAgent("Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:59.0) Gecko/20100101 Firefox/59.0");
    this.page = await this.browser.newPage();
  }

  _setDomCompletTimer = async () => {
    return new Promise(resolve => {
      if(!this.throwErrorIfPageDoesntReachDomComplete) {
        console.log(`Setting timer, complete URL crawl if DOM Complete is not reached within ${this.navigationMsToHaultExecutionAndReturnResults/1_000} seconds.`);
        setTimeout(() => {
          if(!this.navigationFullyCompleted) {
            this.haultedNavigationBeforeReachingDomComplete = true;
            console.log(`Completing URL Crawl early because DOM complete was not reached within ${this.navigationMsToHaultExecutionAndReturnResults/1_000} seconds.`);
            resolve(this.navigationMsToHaultExecutionAndReturnResults);
          }
        }, this.navigationMsToHaultExecutionAndReturnResults)
      }
    })
  }

  _navigateToUrl = async () => {
    const start = Date.now();
    console.log(`navigating to ${this.url}; waitUntil: 'domcontentloaded'; timeout: ${this.timeoutMs}`);
    await this.page.goto(this.url, { 
      // waitUntil: this.pageWaitUntil,
      waitUntil: ['domcontentloaded', 'networkidle2'],
      timeout: this.timeoutMs
    });
    if(!this.haultedNavigationBeforeReachingDomComplete) {
      console.log(`${this.url} reached DOM Complete in ${(Date.now() - start) / 1_000} seconds!`);
      this.navigationFullyCompleted = true;
    }
  }

  _getTagsLoadTypes = async () => {
    if(this.includeTagLoadTypes) {
      const tagUrls = Object.keys(this.requestInterceptor.thirdPartyTags);
      for(let i = 0; i < tagUrls.length; i++) {
        let tagUrl = tagUrls[i];
        this.requestInterceptor.thirdPartyTags[tagUrl].load_type = await this._getScriptTagTypeForUrl(tagUrl);
      }
    }
  }

  _getScriptTagTypeForUrl = async tagUrl => {
    return await this.page.evaluate(tagUrl => {
      try {
        var tag = document.querySelector(`script[src="${tagUrl}"]`) || document.querySelector(`script[src*="${new URL(tagUrl).pathname}"]`);
        if(tag) {
          return tag.async === true ? 'async' : tag.defer === true ? 'defer' : 'synchronous'
        } else {
          return 'http-request'
        }
      } catch(e) {
        console.log(`FAILED TO _getScriptTagTypeForUrl FOR ${tagUrl}`);
        throw Error(e);
      }
    }, tagUrl)
  }
}

module.exports = URLCrawler;