const chromium = require('chrome-aws-lambda');

class PuppeteerModerator {
  async launch() {
    if (!this.browser) {
      this._browser = await this._initializePuppeteer();
      this._page = await this.browser.newPage();
      this._cdpSession = await this._page.target().createCDPSession();
    }
    return this.page;
  }

  async shutdown() {
    if (this.page) await this.page.close();
    if (this.browser) await this.browser.close();
  }

  get browser() {
    return this._browser;
  }

  get page() {
    return this._page;
  }

  get cdpSession() {
    return this._cdpSession;
  }

  _initializePuppeteer = async () => {
    const executablePath = process.env.CHROMIUM_EXECUTABLE || await chromium.executablePath;
    return await chromium.puppeteer.launch({
      args: chromium.args,
      defaultViewport: chromium.defaultViewport,
      executablePath: executablePath,
      headless: false,
    });
  }
}

module.exports = PuppeteerModerator;