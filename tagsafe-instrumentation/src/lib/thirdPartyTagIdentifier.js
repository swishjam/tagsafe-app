import { isThirdPartyUrl, getScriptTagLoadType } from "./utils";

export default class thirdPartyTagIdentifier {
  constructor({ dataReporter, firstPartyDomains, debugMode = false }) {
    this.dataReporter = dataReporter;
    this.firstPartyDomains = firstPartyDomains;
    this.debugMode = debugMode;
  }

  async numTagsNotHostedByTagsafe() {
    return new Promise((resolve, _reject) => {
      if (document.readyState === 'complete') {
        setTimeout(() => resolve(this._countNumThirdPartyTagsNotHostedByTagsafe()), 1_000);
      } else {
        document.addEventListener("readystatechange", (event) => {
          if (event.target.readyState === 'complete') {
            setTimeout(() => resolve(this._countNumThirdPartyTagsNotHostedByTagsafe()), 1_000);
          }
        })
      }
    })
  }

  _countNumThirdPartyTagsNotHostedByTagsafe() {
    if(this.debugMode) console.log('%c[Tagasafe Log] Finding all third party script tags not Tagsafe-hosted...', 'background-color: purple; color: white; padding: 5px;');
    const scriptElsNotTagsafeHosted = Array.from(document.querySelectorAll('script[src]:not([data-tagsafe-hosted])'));
    const thirdPartyScriptElsNotTagsafeHosted = scriptElsNotTagsafeHosted.filter(script => {
      const isThirdPartyTag = isThirdPartyUrl(script.getAttribute('src'), this.firstPartyDomains);
      if(this.debugMode) {
        console.log(`%c[Tagasafe Log] Is ${script.getAttribute('src')} a third party tag? ${isThirdPartyTag}`, 'background-color: purple; color: white; padding: 5px;');
      }
      return isThirdPartyTag;
    })
    return thirdPartyScriptElsNotTagsafeHosted.length;
  }

  // _reportThirdPartyScript(script) {
  //   const loadType = getScriptTagLoadType(script);
  //   const tagUrl = script.getAttribute('src');
  //   this.dataReporter.recordThirdPartyTag({ tagUrl, loadType, interceptedByTagsafeJs: false, optimizedByTagsafeJs: false });
  // }
}