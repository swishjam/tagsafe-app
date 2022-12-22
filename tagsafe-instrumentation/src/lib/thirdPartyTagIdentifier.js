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
    if(document.readyState === 'complete') {
      setTimeout(() => this._findAndReportThirdPartyTags(), 1_000);
    } else {
      document.addEventListener("readystatechange", (event) => {
        if (event.target.readyState === 'complete') {
          setTimeout(() => this._findAndReportThirdPartyTags(), 1_000);
        }
      })
    }
  }
 
  _findAndReportThirdPartyTags() {
    if(this.debugMode) console.log('Finding all third party script tags that ScriptInterceptor missed...');
    Array.from(
      document.querySelectorAll('script[src]:not([data-tagsafe-intercepted])') 
    ).filter(script => {
      const isThirdPartyTag = isThirdPartyUrl(script.getAttribute('src'), this.firstPartyDomains);
      if(this.debugMode) {
        console.log(`Is ${script.getAttribute('src')} a third party tag? ${isThirdPartyTag}`);
      }
      return isThirdPartyTag;
    }).forEach(script => this._reportThirdPartyScript(script))
  }

  _reportThirdPartyScript(script) {
    const loadType = getScriptTagLoadType(script);
    const tagUrl = script.getAttribute('src');
    this.dataReporter.recordThirdPartyTag({ tagUrl, loadType, interceptedByTagsafeJs: false, optimizedByTagsafeJs: false });
  }
}