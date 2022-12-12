import { isThirdPartyUrl, getScriptTagLoadType } from "./utils";

export default class ScriptInterceptor {
  constructor({ 
    tagConfigurations, 
    firstPartyDomains, 
    urlPatternsToNotCapture, 
    dataReporter, 
    debugMode = false 
  }) {
    this.firstPartyDomains = firstPartyDomains;
    this.tagConfigurations = tagConfigurations;
    this.urlPatternsToNotCapture = urlPatternsToNotCapture;
    this.dataReporter = dataReporter;
    this.debugMode = debugMode;
  }

  interceptInjectedScriptTags = () => {
    this._interceptAppendChild();
    this._interceptInsertBefore();
    this._interceptPrepend();
  }

  _interceptAppendChild = () => {
    const ogAppendChild = Node.prototype.appendChild;
    const scope = this;
    Node.prototype.appendChild = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      const returnVal = ogAppendChild.apply(this, arguments);
      // window.dispatchEvent(new Event('Tagsafe::ScriptTagAddedToDOM'), { detail: returnVal });
      return returnVal;
    };
  }

  _interceptInsertBefore = () => {
    const ogInsertBefore = Node.prototype.insertBefore;
    const scope = this;
    Node.prototype.insertBefore = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      const returnVal = ogInsertBefore.apply(this, arguments);
      // window.dispatchEvent(new CustomEvent('Tagsafe::ScriptTagAddedToDOM'), { detail: returnVal });
      return returnVal;
    };
  }

  _interceptPrepend = function() {
    const ogPrepend = Node.prototype.prepend;
    const scope = this;
    Node.prototype.prepend = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      const returnVal = ogPrepend.apply(this, arguments);
      // window.dispatchEvent(new CustomEvent('Tagsafe::ScriptTagAddedToDOM'), { detail: returnVal });
      return returnVal;
    };
  }

  _interceptedInsertAdjacentElement = function() {
    const ogInsertAdjacentElement = Element.prototype.insertAdjacentElement;
    const scope = this;
    Element.prototype.insertAdjacentElement = function() {
      console.error(`Intercepted insertAdjacentElement!!!!`);
      arguments[1] = scope._reMapScriptTagIfNecessary(arguments[1]);
      const returnVal = ogInsertAdjacentElement.apply(this, arguments);
      return returnVal;
    }
  }

  // _interceptAppend = function() {
  //   const ogAppend = Element.prototype.append;
  //   const scope = this;
  //   Element.prototype.append = function() {
  //   }
  // }

  // _interceptPrepend = function () {
  //   const ogPrepend = Element.prototype.prepend;
  //   const scope = this;
  //   Element.prototype.prepend = function () {
  //   }
  // }

  _reMapScriptTagIfNecessary = newNode => {
    try {
      if(newNode.nodeName === 'SCRIPT') {
        const ogSrc = newNode.getAttribute('src');
        const reRouteTagConfig = this.tagConfigurations[ogSrc];
        newNode.setAttribute('data-tagsafe-intercepted', 'true');
        if (isThirdPartyUrl(ogSrc, this.firstPartyDomains)) {
          if (ogSrc && this.urlPatternsToNotCapture.find(pattern => ogSrc.includes(pattern))) {
            window.Tagsafe.bypassedTags = window.Tagsafe.bypassedTags || [];
            window.Tagsafe.bypassedTags.push(ogSrc);
            return newNode;
          } else if (reRouteTagConfig) {
            this.dataReporter.recordInterceptedTag(ogSrc);
            return this._interceptInjectedScriptTag(newNode, reRouteTagConfig);
          } else {
            const loadType = getScriptTagLoadType(newNode);
            this.dataReporter.recordThirdPartyTag({ tagUrl: ogSrc, loadType });
          }
        }
      }
      return newNode;
    } catch(err) {
      console.error(`Tagsafe intercept error: ${err}`);
      return newNode;
    }
  }

  _interceptInjectedScriptTag = (newNode, tagConfig) => {
    try {
      const ogSrc = newNode.getAttribute('src');
      if (tagConfig['configuredTagUrl']) {
        newNode.setAttribute('src', tagConfig['configuredTagUrl']);
        newNode.setAttribute('data-og-src', ogSrc);
      }
      if(tagConfig['sha256']) {
        newNode.setAttribute('integrity', `sha256-${tagConfig['sha256']}`);
        newNode.setAttribute('crossorigin', 'anonymous');
      }
      newNode.setAttribute('data-tagsafe-optimized', 'true');

      if(this.debugMode) {
        console.log(`Intercepted ${ogSrc} ->`);
        console.log({ 
          newUrl: tagConfig['configuredTagUrl'],
          sha256: tagConfig['sha256']
        })
      }

      return newNode; 
    } catch(err) {
      console.error(`Tagsafe intercept error: ${err}`)
      return newNode;
    }
  }
}