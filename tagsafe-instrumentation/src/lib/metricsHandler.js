export default class MetricsHandler {
  constructor() {
    this.timings = {};
    this._initializeListeners();
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

  _listenForFirstContentfulPaint() {
    if(typeof window.PerformanceObserver === 'function') {
      new PerformanceObserver(entryList => {
        (entryList.getEntries() || []).forEach(entry => {
          if (entry.name === "first-contentful-paint") {
            this.timings.fcp = entry.startTime;
            console.log("Recorded FCP Performance: " + entry.startTime);
          }
        });
      }).observe({ type: "paint", buffered: true });
    }
  }

  _listenForLargestContentfulPaint() {
    if(typeof window.PerformanceObserver === 'function') {
      new PerformanceObserver(entryList => {
        (entryList.getEntries() || []).forEach(entry => {
          if (entry.startTime > this.timings.lcp) {
            this.timings.lcp = entry.startTime;
            console.log("Recorded LCP Performance: " + entry.startTime);
          }
        });
      }).observe({ type: "largest-contentful-paint", buffered: true });
    }
  }

  _listenForFirstInputDelay() {
    if (typeof window.PerformanceObserver === 'function') {
      new PerformanceObserver(entryList => {
        (entryList.getEntries() || []).forEach(entry => {
          this.timings.fid = entry.processingStart - entry.startTime;
          console.log("Recorded FOD Performance: " + this.timings.fid);
        });
      }).observe({ type: "first-input", buffered: true });
    }
  }

  _onScriptLoaded(e) {
    // console.log(`${e.target.getAttribute('src')} loaded!`);
  }

  _onScriptFailed(e) {
    // console.log(`${e.target.getAttribute('src')} errored!`);
  }

  _initializeListeners() {
    window.addEventListener('load', e => this._onPageLoad(e));
    if (document.currentScript) this.addScriptTagToMonitor(document.currentScript);
    this._listenForFirstContentfulPaint();
  }
}