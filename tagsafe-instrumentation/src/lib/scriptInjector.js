export default class ScriptInjector {
  constructor({ immediateScripts, onLoadScripts, tagInterceptionRules, disableScriptInterception, debugMode }) {
    this.immediateScripts = immediateScripts;
    this.onLoadScripts = onLoadScripts;
    this.tagInterceptionRules = tagInterceptionRules;
    this.disableScriptInterception = disableScriptInterception;
    this.debugMode = debugMode;
    this.afterAllTagsAddedCallbacks = [];
    this._numTagsInjected = 0;
  }

  beginInjecting() {
    this.immediateScripts.forEach(tagConfig => this._injectScriptIfNecessary(tagConfig));
    window.addEventListener('DOMContentLoaded', () => {
      this.onLoadScripts.forEach(tagConfig => this._injectScriptIfNecessary(tagConfig));
    })
  }

  _injectScriptIfNecessary(tagConfig) {
    try {
      if(this._shouldInjectScript(tagConfig)) {
        const htmlString = window.atob(tagConfig.content);
        const htmlFragment = document.createRange().createContextualFragment(htmlString);
        if (!this.disableScriptInterception) {
          htmlFragment.querySelectorAll('script[src]').forEach(scriptTag => {
            const tagConfig = this.tagInterceptionRules[scriptTag.getAttribute('src')];
            if(tagConfig) {
              this._reRouteScriptSrc(scriptTag, tagConfig)
            }
          })
        }
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

  _reRouteScriptSrc(scriptTag, tagConfig) {
    const ogSrc = scriptTag.getAttribute('src');
    if(this.debugMode) console.log(`[Tagsafe Log] Remapping embedded script tag ${ogSrc} to ${tagConfig['configuredTagUrl']}`, 'background-color: purple; color: white; padding: 5px;');
    if (tagConfig['configuredTagUrl']) {
      scriptTag.setAttribute('src', tagConfig['configuredTagUrl']);
      scriptTag.setAttribute('data-tagsafe-og-src', ogSrc);
      if (ogSrc !== tagConfig['configuredTagUrl']) {
        scriptTag.setAttribute('data-tagsafe-hosted', 'true');
      }
    }
    if (tagConfig['sha256']) {
      scriptTag.setAttribute('integrity', `sha256-${tagConfig['sha256']}`);
      scriptTag.setAttribute('crossorigin', 'anonymous');
    }

    if (['synchronous', 'async', 'defer'].includes(tagConfig['configuredLoadType'])) {
      scriptTag.removeAttribute('async');
      scriptTag.removeAttribute('defer');
      scriptTag.setAttribute(tagConfig['configuredLoadType'], '');
      scriptTag.setAttribute('data-tagsafe-load-strategy-applied', 'true');
    }

    if (this.debugMode) {
      console.log(`%c[Tagsafe Log] Intercepted ${ogSrc} with config:`, 'background-color: purple; color: white; padding: 5px;');
      console.log({
        configuredUrl: tagConfig['configuredTagUrl'],
        configuredLoadType: tagConfig['configuredLoadType'],
        sha256: tagConfig['sha256']
      })
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