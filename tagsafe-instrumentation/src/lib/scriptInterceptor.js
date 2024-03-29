import { isThirdPartyUrl } from "./utils";

export default class ScriptInterceptor {
  constructor({ 
    tagInterceptionRules, 
    firstPartyDomains, 
    disableScriptInterception,
    errorReporter,
    debugMode = false 
  }) {
    this.firstPartyDomains = firstPartyDomains;
    this.tagInterceptionRules = tagInterceptionRules;
    this.debugMode = debugMode;
    this.disableScriptInterception = disableScriptInterception;
    this.errorReporter = errorReporter;
    
    if(this.debugMode && this.disableScriptInterception) {
      console.warn('[Tagsafe Log] Tagsafe CDN re-router is disabled based on configuration sample rate.');
    }
  }

  interceptInjectedScriptTags = () => {
    this._interceptAppendChild();
    this._interceptInsertBefore();
    this._interceptPrepend();
  }

  _interceptAppendChild = () => {
    if (this.disableScriptInterception) return;
    const ogAppendChild = Node.prototype.appendChild;
    const scope = this;
    Node.prototype.appendChild = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      return ogAppendChild.apply(this, arguments);
    };
  }

  _interceptInsertBefore = () => {
    if (this.disableScriptInterception) return;
    const ogInsertBefore = Node.prototype.insertBefore;
    const scope = this;
    Node.prototype.insertBefore = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      return ogInsertBefore.apply(this, arguments);
    };
  }

  _interceptPrepend = function() {
    if (this.disableScriptInterception) return;
    const ogPrepend = Node.prototype.prepend;
    const scope = this;
    Node.prototype.prepend = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      return ogPrepend.apply(this, arguments);
    };
  }

  _interceptedInsertAdjacentElement = function() {
    if (this.disableScriptInterception) return;
    const ogInsertAdjacentElement = Element.prototype.insertAdjacentElement;
    const scope = this;
    Element.prototype.insertAdjacentElement = function() {
      arguments[1] = scope._reMapScriptTagIfNecessary(arguments[1]);
      const returnVal = ogInsertAdjacentElement.apply(this, arguments);
      return returnVal;
    }
  }

  _reMapScriptTagIfNecessary = newNode => {
    try {
      if(newNode.nodeName === 'SCRIPT') {
        const ogSrc = newNode.getAttribute('src');
        const reRouteTagConfig = this.tagInterceptionRules[ogSrc];
        newNode.setAttribute('data-tagsafe-intercepted', 'true');
        if (isThirdPartyUrl(ogSrc, this.firstPartyDomains) && !this.disableScriptInterception && reRouteTagConfig) {
          return this._interceptInjectedScriptTag(newNode, reRouteTagConfig);
        }
      }
      return newNode;
    } catch(err) {
      const errMsg = `[Tagsafe Error] Tagsafe intercept error: ${err}`;
      console.error(errMsg);
      errorReporter.reportError(`${errMsg} - ${err.message}`);
      return newNode;
    }
  }

  _interceptInjectedScriptTag = (newNode, tagConfig) => {
    try {
      const ogSrc = newNode.getAttribute('src');
      if (tagConfig['configuredTagUrl']) {
        newNode.setAttribute('src', tagConfig['configuredTagUrl']);
        newNode.setAttribute('data-tagsafe-og-src', ogSrc);
        if (ogSrc !== tagConfig['configuredTagUrl']) {
          newNode.setAttribute('data-tagsafe-hosted', 'true');
        }
      }
      if (tagConfig['sha256']) {
        newNode.setAttribute('integrity', `sha256-${tagConfig['sha256']}`);
        newNode.setAttribute('crossorigin', 'anonymous');
      }

      if (['synchronous', 'async', 'defer'].includes(tagConfig['configuredLoadType'])) {
        newNode.removeAttribute('async');
        newNode.removeAttribute('defer');
        newNode.setAttribute(tagConfig['configuredLoadType'], '');
        newNode.setAttribute('data-tagsafe-load-strategy-applied', 'true');
      }

      if (this.debugMode) {
        console.log(`%c[Tagsafe Log] Intercepted ${ogSrc} with config:`, 'background-color: #7587f8; color: white; padding: 5px;');
        console.log({ 
          configuredUrl: tagConfig['configuredTagUrl'],
          configuredLoadType: tagConfig['configuredLoadType'],
          sha256: tagConfig['sha256']
        })
      }

      return newNode; 
    } catch(err) {
      console.error(`[Tagsafe Error] Tagsafe intercept error: ${err}`)
      return newNode;
    }
  }
}