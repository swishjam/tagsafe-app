export default class ScriptInterceptor {
  constructor(urlsToInterceptMap) {
    this.urlsToInterceptMap = urlsToInterceptMap;
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
      return scope._reRouteInjectedElIfNecessary(
        arguments[0],
        () => ogAppendChild.apply(appendChildScope, arguments)
      );
    };
  }

  _interceptInsertBefore = () => {
    const ogInsertBefore = Node.prototype.insertBefore;
    const scope = this;
    Node.prototype.insertBefore = function() {
      const insertBeforeScope = this;
      return scope._reRouteInjectedElIfNecessary(
        arguments[0],
        () => ogInsertBefore.apply(insertBeforeScope, arguments)
      );
    };
  }

  _interceptPrepend = function() {
    const ogPrepend = Node.prototype.prepend;
    const scope = this;
    Node.prototype.prepend = function() {
      const prependScope = this;
      return scope._reRouteInjectedElIfNecessary(
        arguments[0],
        () => ogPrepend.apply(prependScope, arguments)
      );
    };
  }

  _reRouteInjectedElIfNecessary = (newNode, dontReRouteCallback) => {
    try {
      if(newNode.nodeName === 'SCRIPT') {
        const reRouteTagConfig = this.urlsToInterceptMap[newNode.getAttribute('src')];
        if(reRouteTagConfig) {
          return this._interceptInjectedScriptTag(newNode, reRouteTagConfig, dontReRouteCallback);
        } else {
          return dontReRouteCallback();
        }
      } else {
        return dontReRouteCallback();
      }
    } catch(err) {
      console.error(`Tagsafe intercept error: ${err}`);
      return dontReRouteCallback();
    }
  }

  _interceptInjectedScriptTag = (newNode, tagConfig, onErrorCallback) => {
    try {
      const ogSrc = newNode.getAttribute('src');
      console.log(`Intercepting Script node ${ogSrc} -> ${tagConfig.tagsafeHostedTagUrl()}`);
      if(tagConfig.tagsafeHostedTagUrl()) {
        newNode.setAttribute('src', tagConfig.tagsafeHostedTagUrl());
        newNode.setAttribute('data-og-src', ogSrc);
      }
      if(tagConfig.sha256()) {
        newNode.setAttribute('integrity', `sha256-${tagConfig.sha256()}`);
        newNode.setAttribute('crossorigin', 'anonymous');
      }
      if(tagConfig.loadRule()) {
        newNode.removeAttribute('async');
        newNode.removeAttribute('defer');
        newNode.setAttribute(tagConfig.loadRule(), 'true');
      }
      newNode.setAttribute('data-tagsafe-intercepted', 'true');
      const domLocation = {
        head: document.head,
        body: document.body
      }[tagConfig.injectLocation()] || document.head;
      domLocation.appendChild(newNode);
      window.Tagsafe.interceptedTags.push([ogSrc, tagConfig.tagsafeHostedTagUrl() || ogSrc]);
      return newNode; 
    } catch(err) {
      console.error(`Tagsafe intecept error: ${err}`)
      return onErrorCallback();
    }
  }
}