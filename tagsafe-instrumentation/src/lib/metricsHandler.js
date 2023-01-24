import Perfume from 'perfume.js';
import { isThirdPartyUrl } from './utils';

const PERFUME_EVENT_TAGSAFE_REPORTING_NAME_DICT = {
  'navigationTiming': 'navigation_timing',
  'FCP': 'first_contentful_paint',
  'TTFB': 'time_to_first_byte',
  'fp': 'first_paint',
  'fcp': 'first_contentful_paint',
  'fid': 'first_input_delay',
  'lcp': 'largest_contentful_paint',
  'cls': 'cumulative_layout_shift',
  'clsFinal': 'cumulative_layout_shift_final',
  'tbt': 'total_blocking_time'
  // 'networkInform'
}

export default class MetricsHandler {
  constructor(dataReporter) {
    this.dataReporter = dataReporter;
    this._initializePerfume();
    window.addEventListener('load', e => this._onPageLoad(e));
  }

  _initializePerfume() {
    new Perfume({
      analyticsTracker: options => {
        const { metricName, data, _navigatorInformation } = options;
        const tagsafeReportingName = PERFUME_EVENT_TAGSAFE_REPORTING_NAME_DICT[metricName];
        if(tagsafeReportingName) {
          this.dataReporter.recordPerformanceMetric(tagsafeReportingName, data);
        }
      }
    })
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
    const numJsTags = jsTags.length;
    // let numThirdPartyJsTags = 0;
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
    this.dataReporter.recordPerformanceMetric('num_tags_hosted_by_tagsafe', numJsTags);
    this.dataReporter.recordPerformanceMetric('num_tags_not_hosted_by_tagsafe', numJsTagsNotHostedByTagsafe);
    this.dataReporter.recordPerformanceMetric('num_tags_with_tagsafe_overridden_load_strategies', numJsTagsWithTagsafeOverriddenLoadStrategies);
  }
}