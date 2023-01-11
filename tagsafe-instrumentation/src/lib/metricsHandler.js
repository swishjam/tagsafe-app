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
}