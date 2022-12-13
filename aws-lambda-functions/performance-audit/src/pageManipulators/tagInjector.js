const fetch = require('node-fetch');

class TagInjector {
  constructor(tagsAndRulesToInject) {
    this.tagsAndRulesToInject = tagsAndRulesToInject;
  }

  injectScriptTagsIntoCheerioDOM = async cheerioDOM => {
    for(let i = 0; i < this.tagsAndRulesToInject.length; i++) {
      let ruleAndUrl = this.tagsAndRulesToInject[i];
      await this._ensureInjectedTagIsValid(ruleAndUrl.url);
      await this._injectScriptTagAndRule(cheerioDOM, ruleAndUrl.url, ruleAndUrl.load_type);
    }
  }

  _injectScriptTagAndRule = async (cheerioDOM, url, loadRule) => {
    let resp = await fetch(url);
    if(resp.status > 299) throw Error(`Injected tag ${url} returned a ${resp.status} response code`);
    if(this.inlineInjectedScriptTags) {
      let inlineJs = await resp.text();
      cheerioDOM('head').append(`
        <script data-tagsafe-injected="true" ${loadRule}=true onload="(function(){ window.tagsafeInjectedTagLoaded = function() {} })();">${inlineJs}</script>`);
    } else {
      console.log('Injected audited tag into DOM.');
      cheerioDOM('head').append(`<script data-tagsafe-injected="true" src="${url}" ${loadRule}=true onload="(function(){ window.tagsafeInjectedTagLoaded = function() {} })();"></script>`);
    } 
  }

  _ensureInjectedTagIsValid = async tagUrl => {
    let response = await fetch(tagUrl);
    if(response.status > 399) {
      throw Error(`Injected URL ${tagUrl} resulted in a ${response.status} response, cannot continue.`);
    }
  }
}

module.exports = TagInjector;