import { isThirdPartyUrl, getScriptTagLoadType } from "./utils";

export default class ScriptInterceptor {
  constructor({ 
    tagInterceptionRules, 
    firstPartyDomains, 
    disableScriptInterception,
    debugMode = false 
  }) {
    this.firstPartyDomains = firstPartyDomains;
    this.tagInterceptionRules = tagInterceptionRules;
    this.debugMode = debugMode;
    this.disableScriptInterception = disableScriptInterception;
    
    this._numTagsHostedByTagsafe = 0;
    this._numTagsWithTagsafeOverriddenLoadStrategies = 0;

    if(this.debugMode && this.disableScriptInterception) {
      console.warn('Tagsafe CDN is disabled based on configuration sample rate.');
    }
  }

  interceptInjectedScriptTags = () => {
    this._interceptAppendChild();
    this._interceptInsertBefore();
    this._interceptPrepend();
  }

  numTagsHostedByTagsafe = () => this._numTagsHostedByTagsafe;
  numTagsWithTagsafeOverriddenLoadStrategies = () => this._numTagsWithTagsafeOverriddenLoadStrategies;

  _interceptAppendChild = () => {
    const ogAppendChild = Node.prototype.appendChild;
    const scope = this;
    Node.prototype.appendChild = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      return ogAppendChild.apply(this, arguments);
    };
  }

  _interceptInsertBefore = () => {
    const ogInsertBefore = Node.prototype.insertBefore;
    const scope = this;
    Node.prototype.insertBefore = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      return ogInsertBefore.apply(this, arguments);
    };
  }

  _interceptPrepend = function() {
    const ogPrepend = Node.prototype.prepend;
    const scope = this;
    Node.prototype.prepend = function() {
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      return ogPrepend.apply(this, arguments);
    };
  }

  _interceptedInsertAdjacentElement = function() {
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
      console.error(`Tagsafe intercept error: ${err}`);
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
          this._numTagsHostedByTagsafe += 1;
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
        this._numTagsWithTagsafeOverriddenLoadStrategies += 1;
      }

      if (this.debugMode) {
        console.log(`Intercepted ${ogSrc} with config:`);
        console.log({ 
          configuredUrl: tagConfig['configuredTagUrl'],
          configuredLoadType: tagConfig['configuredLoadType'],
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