module.exports = class RequestInterceptor {
  constructor({ page, requestOverrideMap }) {
    this.page = page;
    this.requestOverrideMap = requestOverrideMap;
    this._didOverwriteRequest = false;
  }

  didOverwriteRequest = () => this._didOverwriteRequest;

  async overrideProvidedRequests() {
    await this.page.setRequestInterception(true);
    this.page.on('request', async req => {
      const urlToOverrideTo = this._urlToOverrideRequestUrlTo(req.url())
      if(urlToOverrideTo) {
        console.log(`Intercepting ${req.url()} and overriding it to ${urlToOverrideTo}!`);
        await req.continue({ url: urlToOverrideTo });
        this._didOverwriteRequest = true;
      } else {
        req.continue();
      }
    })
  }

  _urlToOverrideRequestUrlTo(url) {
    const parsedUrl = new URL(url);
    return this.requestOverrideMap[parsedUrl.href] ||
              this.requestOverrideMap[`${parsedUrl.hostname}${parsedUrl.pathname}`] ||
              this.requestOverrideMap[`${parsedUrl.protocol}//${parsedUrl.hostname}${parsedUrl.pathname}`];

  }
}