import { isThirdPartyUrl, getScriptTagLoadType } from "./utils";

export default class thirdPartyTagIdentifier {
  constructor({ dataReporter, firstPartyDomains, debugMode = false }) {
    this.dataReporter = dataReporter;
    this.firstPartyDomains = firstPartyDomains;
    this.debugMode = debugMode;
  }

  reportAllThirdPartyTags() {
    // console.log('Going to look for scripts in 5 seconds....');
    // setTimeout(() => this._findAndReportThirdPartyTags(), 5_000);
    if(document.readyState === 'interactive') {
      this._findAndReportThirdPartyTags();
    } else {
      document.addEventListener("readystatechange", (event) => {
        if (event.target.readyState === 'interactive') {
          this._findAndReportThirdPartyTags();
        }
      })
    }
  }
 
  _findAndReportThirdPartyTags() {
    window.Tagsafe.identifiedThirdPartyTags = [];
    const thirdPartyTags = Array.from(
      document.querySelectorAll('script[src]:not([data-tagsafe-intercepted])')
    ).filter(script => isThirdPartyUrl(script.getAttribute('src'), this.firstPartyDomains));
    thirdPartyTags.forEach(script => {
      const tagUrl = script.getAttribute('src');
      const loadType = getScriptTagLoadType(script);
      this.dataReporter.recordThirdPartyTag({ tagUrl, loadType });
    })
  }
}