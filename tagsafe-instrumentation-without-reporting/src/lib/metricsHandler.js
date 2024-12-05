import { isThirdPartyUrl } from './utils';

export default class MetricsHandler {
  constructor(dataReporter) {
    this.dataReporter = dataReporter;
    window.addEventListener('load', e => this._onPageLoad(e));
  }

  _onPageLoad = _event => {
    this.dataReporter.recordPerformanceMetric('dom_complete', this._measurePerformanceAttribute('domComplete'));
    this.dataReporter.recordPerformanceMetric('dom_interactive', this._measurePerformanceAttribute('domInteractive'));
    this.dataReporter.recordPerformanceMetric('dom_loading', this._measurePerformanceAttribute('domLoading'));
    this._reportThirdPartyJsNetworkTime();
    this._reportJsTagMetrics();
  }

  _measurePerformanceAttribute(attr) {
    return window.performance.timing[attr] - window.performance.timing.navigationStart;
  }

  _reportThirdPartyJsNetworkTime() {
    let thirdPartyJsNetworkTime = 0;
    window.performance.getEntriesByType('resource').forEach(resource => {
      if (resource.initiatorType === 'script') {
        try {
          if (isThirdPartyUrl(resource.name)) thirdPartyJsNetworkTime += resource.duration
        } catch (err) { }
      }
    })
    this.dataReporter.recordPerformanceMetric('third_party_js_network_time', thirdPartyJsNetworkTime);
  }

  _reportJsTagMetrics() {
    const jsTags = document.querySelectorAll('script[src]');
    let numJsTagsHostedByTagsafe = 0;
    let numJsTagsNotHostedByTagsafe = 0;
    let numJsTagsWithTagsafeOverriddenLoadStrategies = 0;
    jsTags.forEach(script => {
      try {
        if (isThirdPartyUrl(script.src) && !script.getAttribute('data-tagsafe-hosted')) numJsTagsNotHostedByTagsafe++;
        if (script.getAttribute('data-tagsafe-hosted')) numJsTagsHostedByTagsafe++;
        if (script.getAttribute('data-tagsafe-load-strategy-applied')) numJsTagsWithTagsafeOverriddenLoadStrategies++;
      } catch (err) {}
    });
    this.dataReporter.recordNumTagsafeHostedTags(numJsTagsHostedByTagsafe);
    this.dataReporter.recordNumTagsNotHostedByTagsafe(numJsTagsNotHostedByTagsafe);
    this.dataReporter.recordNumTagsWithTagsafeOverriddenLoadStrategies(numJsTagsWithTagsafeOverriddenLoadStrategies);
  }
}