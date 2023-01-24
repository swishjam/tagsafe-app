export default class ScriptInjector {
  constructor({ immediateScripts, onLoadScripts, debugMode }) {
    this.immediateScripts = immediateScripts;
    this.onLoadScripts = onLoadScripts;
    this.debugMode = debugMode;
    this.afterAllTagsAddedCallbacks = [];
    this._numTagsInjected = 0;
  }

  beginInjecting() {
    this.immediateScripts.forEach(scriptConfig => this._injectScript(scriptConfig));
    window.addEventListener('DOMContentLoaded', () => {
      this.onLoadScripts.forEach(scriptConfig => this._injectScript(scriptConfig));
    })
  }

  _injectScript(scriptConfig) {
    const script = document.createElement('script');
    script.setAttribute('data-tagsafe-injected', 'true');
    script.setAttribute('data-tagsafe-tag-snippet', scriptConfig.uid);
    script.innerText = scriptConfig.js;
    scriptConfig.attrs.forEach(attr => script.setAttribute(attr[0], attr[1]));
    document.head.appendChild(script);
    this._numTagsInjected += 1;
    if(this.debugMode) {
      console.log(`Tagsafe added ${scriptConfig.uid} to DOM.`)
    }
  }
}