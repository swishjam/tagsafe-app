const chromium = require('chrome-aws-lambda');

class PuppeteerModerator {
  constructor() {
    // this.slowMoMs = slowMoMs
  }

  async launch() {
    if(!this.browser) {
      this._browser = await this._initializePuppeteer();
      this._page = await this.browser.newPage();
    }
    return this.page;
  }

  async shutdown() {
    if(this.page) await this.page.close();
    if(this.browser) await this.browser.close();
  }

  get browser() {
    return this._browser;
  }

  get page() {
    return this._page;
  }

  _initializePuppeteer = async () => {
    const executablePath = process.env.CHROMIUM_EXECUTABLE || await chromium.executablePath;
    return await chromium.puppeteer.launch({
      args: chromium.args,
      defaultViewport: chromium.defaultViewport,
      executablePath: executablePath,
      headless: false,
      // slowMo: this.slowMoMs
    });
  }
}

module.exports = PuppeteerModerator;