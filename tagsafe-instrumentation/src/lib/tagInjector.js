import DOMListener from "./domListener";

export default class TagInjector {
  constructor({ tagConfigsToInjectImmediately = [], tagConfigsToInjectOnLoad = [] }) {
    this.tagConfigsToInjectImmediately = tagConfigsToInjectImmediately;
    this.tagConfigsToInjectOnLoad = tagConfigsToInjectOnLoad;
  }

  injectTagsIntoDOM() {
    this._injectTags(this.tagConfigsToInjectImmediately);
    window.addEventListener('load', () => this._injectTags(this.tagConfigsToInjectOnLoad) );
  }

  _injectTags(tagConfigurations) {
    tagConfigurations.forEach(tagConfig => this._injectTag(tagConfig) );
  }

  _injectTag(tagConfiguration) {
    console.log(`Injecting tag:`)
    console.log(tagConfiguration);
    const el = document.createElement(tagConfiguration.el());
    el.setAttribute(tagConfiguration.loadRule(), 'true');
    el.setAttribute('src', tagConfiguration.tagsafeHostedTagUrl());
    el.setAttribute('data-tagsafe-og-url', tagConfiguration.directTagUrl());
    const domLocation = {
      head: document.head,
      body: document.body
    }[tagConfiguration.injectLocation()];
    new DOMListener(el);
    domLocation.appendChild(el);
    console.log(`Tagsafe added the ${tagConfiguration.tagsafeHostedTagUrl()} tag to the DOM.`);
  }
}