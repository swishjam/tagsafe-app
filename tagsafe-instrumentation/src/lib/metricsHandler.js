export default class MetricsHandler {
  constructor() {
    this.timings = {};
    window.addEventListener('load', e => this._onPageLoad(e))
    if(document.currentScript) this.addScriptTagToMonitor(document.currentScript);
  }

  addScriptTagToMonitor(script) {
    script.addEventListener('load', e => this._onScriptLoaded(e))
    script.addEventListener('error', e => this._onScriptFailed(e))
  }

  _onPageLoad = _event => {
    this.timings = {
      DOMComplete: this._measurePerformanceAttribute('domComplete'),
      DOMInteractive: this._measurePerformanceAttribute('domInteractive'),
      DOMLoading: this._measurePerformanceAttribute('domLoading'),
    }
  }

  _measurePerformanceAttribute(attr) {
    return window.performance.timing[attr] - window.performance.timing.navigationStart;
  }

  _onScriptLoaded(e) {
    console.log(`${e.target.getAttribute('src')} loaded!`);
  }

  _onScriptFailed(e) {
    console.log(`${e.target.getAttribute('src')} errored!`);
  }
}