class ThirdPartyTagScrubber {
  constructor({ thirdPartyTagDetector, pageEventHandler }) {
    this.thirdPartyTagDetector = thirdPartyTagDetector;
    this.pageEventHandler = pageEventHandler;
  }

  scrubThirdPartyTagsFromCheerioDOM = cheerioDOM => {
    console.log('Removing third party tags embedded in HTML');
    const scriptTags = cheerioDOM('script');
    Array.from(scriptTags).forEach(script => {
      let tagUrl = script.attribs['src'];
      if(this._shouldScrubScriptTag(tagUrl)) {
        if(tagUrl && this.thirdPartyTagDetector.isAllowedThirdPartyUrl(tagUrl)) {
          console.log(`Allowing ${tagUrl} third party tag because it's an allowed tag.`);
          this.pageEventHandler.emit('THIRD_PARTY_TAG_ALLOWED', tagUrl);
        } else {
          console.log(`Removing ${tagUrl} from DOM.`);
          cheerioDOM(script).remove();
          this.pageEventHandler.emit('RESOURCE_BLOCKED', this.thirdPartyTagDetector.fullUrl(tagUrl), 'script')
        }
      } else {
        console.log(`Keeping ${tagUrl || 'inlined script tag'} because it is not a third party tag.`);
      }
    });
  }

  _shouldScrubScriptTag = url => {
    try {
      return this.thirdPartyTagDetector.isThirdPartyUrl(url);
    } catch(err) {
      console.log(`Unable to determine if ${url} is a third party tag: ${err.stack}`);
      console.log(`Assuming it is first party.`);
      return false;
    }
  }
}

module.exports = ThirdPartyTagScrubber;