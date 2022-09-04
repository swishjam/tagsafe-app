import ScriptInterceptor from './scriptInterceptor';

export default class TagInjector {
  constructor({ 
    tagConfigsToInjectImmediately = [], 
    tagConfigsToInjectOnLoad = [],
    metricsHandler,
    errorHandler
  }) {
    this.tagConfigsToInjectImmediately = tagConfigsToInjectImmediately;
    this.tagConfigsToInjectOnLoad = tagConfigsToInjectOnLoad;
    this.metricsHandler = metricsHandler;
    this.errorHandler = errorHandler;
    window.Tagsafe.injectedTags = [];
  }

  injectTagsIntoDOM() {
    this._setupScriptInterceptor();
    this._injectTags(this.tagConfigsToInjectImmediately);
    window.addEventListener('load', () => this._injectTags(this.tagConfigsToInjectOnLoad) );
  }

  _setupScriptInterceptor = () => {
    let scriptUrlsToInterceptMap = {};
    this.tagConfigsToInjectImmediately.concat(this.tagConfigsToInjectOnLoad).forEach(tagConfig => {
      if(tagConfig.directTagUrl() && tagConfig.tagsafeHostedTagUrl()) {
        scriptUrlsToInterceptMap[tagConfig.directTagUrl()] = tagConfig.tagsafeHostedTagUrl();
      }
    })
    const scriptInterceptor = new ScriptInterceptor(scriptUrlsToInterceptMap);
    scriptInterceptor.interceptInjectedScriptTags();
  }

  _injectTags(tagConfigurations) {
    tagConfigurations.forEach(tagConfig => this._injectTag(tagConfig) );
  }

  _injectTag(tagConfiguration) {
    try {
      const el = document.createElement(tagConfiguration.el());
      el.setAttribute('data-tagsafe-injected', 'true');
      el.setAttribute('data-tagsafe-tag-uid', tagConfiguration.uid());
      if(tagConfiguration.loadRule()) el.setAttribute(tagConfiguration.loadRule(), 'true');
      if(tagConfiguration.script()) {
        el.setAttribute('data-tagsafe-inline-script', 'true')
        el.innerText = tagConfiguration.script();
      } else if(tagConfiguration.tagsafeHostedTagUrl()) {
        el.setAttribute('data-tagsafe-og-url', tagConfiguration.directTagUrl());
        el.setAttribute('data-tagsafe-hosted', 'true');
        el.setAttribute('src', tagConfiguration.tagsafeHostedTagUrl());
      } else if(tagConfiguration.directTagUrl()) {
        el.setAttribute('data-tagsafe-hosted', 'false');
        el.setAttribute('src', tagConfiguration.directTagUrl());
      }
      // el.setAttribute('integrity', `sha256-${tagConfiguration.sha256()}`);
      // el.setAttribute('crossorigin', 'anonymous');
      const domLocation = {
        head: document.head,
        body: document.body
      }[tagConfiguration.injectLocation()];
      this.metricsHandler.addScriptTagToMonitor(el);
      domLocation.appendChild(el);
      window.Tagsafe.injectedTags.push(tagConfiguration.toJson());
    } catch(err) {
      console.error(`Tagsafe script injection error, cannot inject ${tagConfiguration.directTagUrl() || tagConfiguration.uid()}: ${err}`);
      this.errorHandler.captureError(err)
    }
  }
}