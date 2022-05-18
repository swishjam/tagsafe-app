class ThirdPartyTagDetector {
  constructor({ firstPartyUrl, urlPatternsToAllow, allowAllThirdPartyTags = false, thirdPartyTagUrlPatternsToNeverAllow = [] }) {
    this.firstPartyUrl = firstPartyUrl;
    this.urlPatternsToAllow = urlPatternsToAllow;
    this.thirdPartyTagUrlPatternsToNeverAllow = thirdPartyTagUrlPatternsToNeverAllow;
    this.allowAllThirdPartyTags = allowAllThirdPartyTags;
  }

  isThirdPartyUrl = url => {
    if(!url) return false;
    const fullUrl = this.fullUrl(url);
    if(process.env.CONSIDER_SUBDOMAINS_FIRST_PARTY === 'true') {
      const isFirstPartyFullPath = this._hostnameForUrl(fullUrl) === this._hostnameForUrl(this.firstPartyUrl);
      return !isFirstPartyFullPath;
    } else {
      const isFirstPartyFullPath = this._domainForUrl(fullUrl) === this._domainForUrl(this.firstPartyUrl);
      return !isFirstPartyFullPath;
    }
  }

  isAllowedThirdPartyUrl = url => {
    return(
      ( this.allowAllThirdPartyTags && !this.thirdPartyTagUrlPatternsToNeverAllow.some(urlPattern => url.includes(urlPattern)) ) || 
      ( this.urlPatternsToAllow.some(urlPattern => url.includes(urlPattern)) )
    )
  }

  fullUrl = url => {
    if(!url) return;
    if(url.startsWith('//')) {
      // accounts for: '//edge1.certona.net/cd/a691d6e4/canadiantire.ca/scripts/resonance.js'
      return `https:${url}`;
    } else if(url.startsWith('/')) { 
      return `${this.firstPartyUrl}${url}`
    } else {
      return url
    }
  }

  _hostnameForUrl = urlString => {
    return new URL(urlString).hostname
  }

  _domainForUrl = url => {
    const splitUrlHost = this._hostnameForUrl(url).split('.');
    splitUrlHost.shift();
    return splitUrlHost.join('.');
  }
}

module.exports = ThirdPartyTagDetector;