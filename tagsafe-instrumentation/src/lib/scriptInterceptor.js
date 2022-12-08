import { urlToDomain } from "./utils";

export default class ScriptInterceptor {
  constructor({ tagConfigurations, firstPartyDomains, dataReporter, debugMode = false }) {
    this.firstPartyDomains = firstPartyDomains;
    this.tagConfigurations = tagConfigurations;
    this.dataReporter = dataReporter;
    this.debugMode = debugMode;
    window.Tagsafe.interceptedTags = [];
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
      const appendChildScope = this;
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      ogAppendChild.apply(appendChildScope, arguments);
    };
  }

  _interceptInsertBefore = () => {
    const ogInsertBefore = Node.prototype.insertBefore;
    const scope = this;
    Node.prototype.insertBefore = function() {
      const insertBeforeScope = this;
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      ogInsertBefore.apply(insertBeforeScope, arguments);
    };
  }

  _interceptPrepend = function() {
    const ogPrepend = Node.prototype.prepend;
    const scope = this;
    Node.prototype.prepend = function() {
      const prependScope = this;
      arguments[0] = scope._reMapScriptTagIfNecessary(arguments[0]);
      // ogPrepend.apply(prependScope, arguments)
      ogPrepend.apply(this, arguments);
    };
  }

  _reMapScriptTagIfNecessary = newNode => {
    try {
      if(newNode.nodeName === 'SCRIPT') {
        const ogSrc = newNode.getAttribute('src');
        const reRouteTagConfig = this.tagConfigurations[ogSrc];
        if(reRouteTagConfig) {
          return this._interceptInjectedScriptTag(newNode, reRouteTagConfig);
        } else {
          if(this._isThirdPartySrc(ogSrc)) {
            const loadType = newNode.getAttribute('async') !== null ? 'async' : 
                              newNode.getAttribute('defer') !== null ? 'defer' : 'synchronous';
            this.dataReporter.recordNewTag({ tagUrl: ogSrc, loadType });
          }
          return newNode;
        }
      } else {
        return newNode;
      }
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
      newNode.setAttribute('data-tagsafe-intercepted', 'true');

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

  _isThirdPartySrc = src => {
    if(src && src !== '') {
      return !this.firstPartyDomains.includes(urlToDomain(src));
    }
  }
}