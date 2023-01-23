export default class ScriptInector {
  constructor({ immediateScripts, onLoadScripts, debugMode }) {
    this.immediateScripts = immediateScripts;
    this.onLoadScripts = onLoadScripts;
    this.debugMode = debugMode;
    this.afterAllTagsAddedCallbacks = [];
    this._numTagsInjected = 0;
  }

  beginInjecting() {
    this.immediateScripts.forEach(tagConfig => this._injectScriptIfNecessary(tagConfig));
    window.addEventListener('DOMContentLoaded', () => {
      this.onLoadScripts.forEach(tagConfig => this._injectScriptIfNecessary(tagConfig));
      this.afterAllTagsAddedCallbacks.forEach(callback => callback());
    })
  }

  afterAllTagsAdded(callback) {
    this.afterAllTagsAddedCallbacks.push(callback);
  }

  numTagsInjected = () => this._numTagsInjected;

  _injectScriptIfNecessary(tagConfig) {
    try {
      if(this._shouldInjectScript(tagConfig)) {
        const htmlString = window.atob(tagConfig.content);
        const htmlFragment = document.createRange().createContextualFragment(htmlString);
        document.head.appendChild(htmlFragment);
        this._numTagsInjected += 1;
        if (this.debugMode) {
          console.log(`%c[Tagsafe Log] Added ${tagConfig.uid} to DOM.`, 'background-color: purple; color: white; padding: 5px;')
        }
      } else if (this.debugMode) {
        console.log(`%c[Tagsafe Log] Ignored ${tagConfig.uid} tag because it is not configured to be added to this URL.`, 'background-color: purple; color: white; padding: 5px;')
      }
    } catch(err) {
      console.warn(`[Tagsafe Error] Unable to add tag ${tagConfig.uid}`);
    }
  }

  _shouldInjectScript(tagConfig) {
    if (tagConfig.ignoreUrls.find((rule => window.location.href.includes(rule.urlPattern) ))) {
      return false;
    } else if(tagConfig.injectUrls === '*') {
      return true;
    } else {
      return tagConfig.injectUrls.find(rule => window.location.href.includes(rule.urlPattern));
    }
  }
}