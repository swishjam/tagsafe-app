const chromium = require('chrome-aws-lambda'),
        fs = require('fs'),
        cheerio = require('cheerio'),
        S3 = require('./s3.js');

require('dotenv').config();

class Snapshotter {
  constructor({ url, pageManipulator, options = {} }) {
    this.url = url;
    this.pageManipulator = pageManipulator;

    this.additionalWaitMs = options['additionalWaitMs'];
    this.navigationTimeoutMs = options['navigationTimeoutMs'];
    this.continueOnNavigationTimeout = options['continueOnNavigationTimeout'];
    this.scrollPage = typeof options['scrollPage'] === 'undefined' ? true : options['scrollPage'];
    
    this.logAllPageConsoleLogs = process.env.LOG_ALL_PAGE_CONSOLE_LOGS === 'true';
    this.filename = `${this.url.replace(/\\|\:|\.|\//g, '_')}-${Date.now()}-${parseInt(Math.random()*10000000000)}`
    this.navigationTimedOut = false;
  }

  takeSnapshot = async () => {
    await this._launchPuppeteer();
    await this.pageManipulator.preparePage(this.page);
    await this._navigateToUrl();
    await this._ensureInjectedTagsHaveLoaded();
    await this._scrollToBottomOfPage();
    await this._waitAdditionalMs();
    await this._sanitizeAndUploadHtmlToS3();
    await this._takeAndUploadScreenshotToS3();
    await this._killBrowser();
  }

  _launchPuppeteer = async () => {
    console.log('Beginning _launchPuppeteer...')
    this.browser = await chromium.puppeteer.launch({
      args: chromium.args,
      defaultViewport: chromium.defaultViewport,
      executablePath: process.env.CHROMIUM_EXECUTABLE || await chromium.executablePath
    });
    this.page = await this.browser.newPage();
    await this.page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/97.0.4692.99 Safari/537.36');
    this.page.on('console', this._handleConsoleLog)
    console.log('Completed _launchPuppeteer...')
  }

  _handleConsoleLog = log => {
    if(log.text().startsWith('TAGSAFE_LOG::')) {
      let splitTagsafeLog = log.text().split('::');
      let callbackType = splitTagsafeLog[1];
      let payload = splitTagsafeLog[2];
      let callback = {
        LOG: msg => { console.log(`== TAGSAFE LOG == ${msg}`) },
        ERROR: msg => { throw Error(msg) }
      }[callbackType];
      if(callback) callback(payload);
    } else if(this.logAllPageConsoleLogs) {
      console.log(`~~ PAGE LOG ~~  ${log.type()}: ${log.text()}`)
    }
  }

  _navigateToUrl = async () => {
    let navigationStartTime = Date.now();
    console.log(`Navigating to ${this.url}`);
    try {
      await this.page.goto(this.url, { 
        timeout: this.navigationTimeoutMs, 
        waitUntil: ['domcontentloaded', 'networkidle2'] 
      });
      console.log(`Successfully reached ${this.url} in ${(Date.now() - navigationStartTime)/1000} seconds.`);
    } catch(e) {
      this.navigationTimedOut = true;
      console.log(`Encountered error in \`_navigateToUrl\`: ${e.message}`)
      if(this.continueOnNavigationTimeout) {
        console.log('Continuing anyway because continueOnNavigationTimeout = true');
      } else {
        throw Error(e);
      }
    }
  }

  _ensureInjectedTagsHaveLoaded = async () => {
    console.log('Beginning _ensureInjectedTagsHaveLoaded...')
    if(this.pageManipulator.thirdPartyTagUrlsAndRulesToInject.length > 0) {
      let startTime = Date.now();
      console.log('Ensuring Tagsafe injected tags have loaded...');
      try {
        await this.page.waitForFunction('window.tagsafeInjectedTagLoaded');
        console.log(`Tagsafe injected tags have loaded after waiting ${(Date.now() - startTime)/1000} seconds, continuing...`);
      } catch(e) {
        throw Error(`Tagsafe injected tag never loaded after waiting ${(Date.now() - startTime)/1000} seconds.`)
      }
    } else {
      console.log('No injected tags to ensure load.');
    }
    console.log('Completed _ensureInjectedTagsHaveLoaded...')
  }

  _scrollToBottomOfPage = async () => {
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

  _waitAdditionalMs = async () => {
    console.log(`Waiting additional ${this.additionalWaitMs} ms.`);
    return new Promise(resolve => setTimeout(() => {
      console.log('Done waiting!');
      resolve();
    }, this.additionalWaitMs));
  }

  _sanitizeAndUploadHtmlToS3 = async () => {
    console.log('Beginning _sanitizeAndUploadHtmlToS3...');
    const rawHtml = await this.page.content();
    const $ = cheerio.load(rawHtml);
    (this.pageManipulator.thirdPartyTagsAllowed).concat(this.pageManipulator.thirdPartyTagsBlocked).forEach(scriptUrl => {
      let tagToStrip = $(`script[src="${scriptUrl}"]`);
      console.log(`Removing ${scriptUrl} from DOM`);
      if(tagToStrip) $(tagToStrip).remove();
    })
    this.htmlS3Location = await S3.uploadToS3($.html(), `${this.filename}.html`);
    console.log('Completed HTML upload to S3...');
    return this.htmlS3Location;
  }

  _takeAndUploadScreenshotToS3 = async () => {
    console.log('Beginning _takeAndUploadScreenshotToS3...');
    const tempScreenshotLocation = `/tmp/${this.filename}.png`;
    await this.page.screenshot({ path: tempScreenshotLocation, fullPage: true });
    this.screenshotS3Location = await S3.uploadToS3(fs.readFileSync(tempScreenshotLocation), `${this.filename}.png`, true);
    fs.unlinkSync(tempScreenshotLocation);
    console.log('Completed screenshot upload to S3...');
    return this.screenshotS3Location;
  }

  _killBrowser = async () => {
    console.log('Beginning _killBrowser...')
    if(this.page) await this.page.close();
    if(this.browser) await this.browser.close();
    console.log('Completed _killBrowser...')
  }
}

module.exports = Snapshotter;