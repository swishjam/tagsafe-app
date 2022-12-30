import Perfume from 'perfume.js';

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

  // _initializePerfume() {
  //   new Perfume({
  //     analyticsTracker: (options) => {
  //       const { metricName, data, navigatorInformation } = options;
  //       switch (metricName) {
  //         case 'navigationTiming':
  //           if (data && data.timeToFirstByte) {
  //             this.dataReporter.recordPerformanceMetric('navigation_timing', data);
  //           }
  //           break;
  //         case 'networkInformation':
  //         //   if (data && data.effectiveType) {
  //         //     this.dataReporter.recordPerformanceMetric('network_information', data);
  //         //   }
  //           break;
  //         case 'FCP':
  //           this.dataReporter.recordPerformanceMetric('first_contentful_paint', { duration: data });
  //           break;
  //         case 'TTFB':
  //           this.dataReporter.recordPerformanceMetric('time_to_first_byte', { duration: data });
  //         case 'fp':
  //           this.dataReporter.recordPerformanceMetric('first_paint', { duration: data });
  //           break;
  //         case 'fcp':
  //           this.dataReporter.recordPerformanceMetric('first_contentfulPaint', { duration: data });
  //           break;
  //         case 'fid':
  //           this.dataReporter.recordPerformanceMetric('first_input_delay', { duration: data });
  //           break;
  //         case 'lcp':
  //           this.dataReporter.recordPerformanceMetric('largest_contentful_paint', { duration: data });
  //           break;
  //         case 'cls':
  //           this.dataReporter.recordPerformanceMetric('cumulative_layout_shift', { duration: data });
  //           break;
  //         case 'clsFinal':
  //           this.dataReporter.recordPerformanceMetric('cumulative_layout_shift_final', { duration: data });
  //           break;
  //         case 'tbt':
  //           this.dataReporter.recordPerformanceMetric('total_blocking_time', { duration: data });
  //           break;
  //         default:
  //           this.dataReporter.recordPerformanceMetric(metricName, { duration: data });
  //           break;
  //       }
  //     },
  //   });
  // }

  _onPageLoad = _event => {
    this.dataReporter.recordPerformanceMetric('dom_complete', this._measurePerformanceAttribute('domComplete'));
    this.dataReporter.recordPerformanceMetric('dom_interactive', this._measurePerformanceAttribute('domInteractive'));
    this.dataReporter.recordPerformanceMetric('dom_loading', this._measurePerformanceAttribute('domLoading'));
  }

  _measurePerformanceAttribute(attr) {
    return window.performance.timing[attr] - window.performance.timing.navigationStart;
  }
}