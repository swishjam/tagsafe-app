export default class DataReporter {
  constructor({ reportingURL, containerUid, reportingSampleRate = 1, debugMode = false }) {
    this.dataToReport = { third_party_tags: [], performance_metrics: {}, errors: [], warnings: [] };
    this.dataReported = { third_party_tags: [], performance_metrics: {}, errors: [], warnings: [] };
    this.lastReceivedDataAt = null;
    this.reportingURL = reportingURL;
    this.containerUid = containerUid;
    this.debugMode = debugMode;

    window.Tagsafe.identifiedThirdPartyTags = [];
    window.Tagsafe.optimizedTags = [];

    // sample rate of 1 means capture everything, 0 means capture nothing
    this.reportingEnabled = Math.random() < reportingSampleRate;
    if (this.reportingEnabled) { 
      if(this.debugMode) console.log(`%c[Tagsafe Log] Reporting is enabled (sample rate is set to ${reportingSampleRate * 100}%).`, 'background-color: purple; color: white; padding: 5px;');
      this._startReportingInterval();
      window.Tagsafe.config.reportingEnabled = true;
    } else {
      if (this.debugMode) console.log(`%c[Tagsafe Log] Reporting is disabled (sample rate is set to ${reportingSampleRate * 100}%).`, 'background-color: purple; color: white; padding: 5px;');
      window.Tagsafe.config.reportingEnabled = false;
    }
  }

  recordThirdPartyTag({ tagUrl, loadType, interceptedByTagsafeJs, optimizedByTagsafeJs }) {
    window.Tagsafe.identifiedThirdPartyTags.push(tagUrl);
    this._recordData('third_party_tags', { 
      tag_url: tagUrl, 
      load_type: loadType,
      intercepted_by_tagsafe_js: interceptedByTagsafeJs,
      optimized_by_tagsafe_js: optimizedByTagsafeJs
    });
  }

  // recordNumTagsafeInjectedTags(numTags) {
  //   this.dataToReport['num_tagsafe_injected_tags'] = numTags;
  //   if(this.debugMode) {
  //     console.log(`%c[Tagsafe Log] recording num_tagsafe_injected_tags: ${numTags}`, 'background-color: purple; color: white; padding: 5px;');
  //   }
  // }

  recordNumTagsafeHostedTags(numTags) {
    this.dataToReport['num_tagsafe_hosted_tags'] = numTags;
    if(this.debugMode) {
      console.log(`%c[Tagsafe Log] recording num_tagsafe_hosted_tags: ${numTags}`, 'background-color: purple; color: white; padding: 5px;');
    }
  }

  recordNumTagsWithTagsafeOverriddenLoadStrategies(numTags) {
    this.dataToReport['num_tags_with_tagsafe_overridden_load_strategies'] = numTags;
    if (this.debugMode) {
      console.log(`%c[Tagsafe Log] recording num_tags_with_tagsafe_overridden_load_strategies: ${numTags}`, 'background-color: purple; color: white; padding: 5px;');
    }
  }

  recordNumTagsNotHostedByTagsafe(numTags) {
    this.dataToReport['num_tags_not_hosted_by_tagsafe'] = numTags;
    if(this.debugMode) {
      console.log(`%c[Tagsafe Log] recording num_tags_not_hosted_by_tagsafe: ${numTags}`, 'background-color: purple; color: white; padding: 5px;');
    }
  }
 
  recordPerformanceMetric(metricName, data) {
    this.dataToReport.performance_metrics[metricName] = data;
    this.lastReceivedDataAt = Date.now();
    if(this.debugMode && this.reportingEnabled) {
      console.log(`%c[Tagsafe Log] New reporting data to report: ${metricName}`, 'background-color: purple; color: white; padding: 5px;');
      console.log(data);
    }
  }

  recordWarning(warning) {
    this._recordData('warnings', warning);
  }

  recordError(err) {
    this._recordData('errors', err);
  }

  _recordData(type, data) {
    this.dataToReport[type].push(data);
    this.lastReceivedDataAt = Date.now();
    if(this.debugMode && this.reportingEnabled) {
      console.log(`New ${type} data to report to Tagsafe API`);
      console.log(data);
    }
  }

  _startReportingInterval() {
    setInterval(async () => {
      // if it's been > 5 seconds since the last data was received
      if (this.lastReceivedDataAt && Date.now() - this.lastReceivedDataAt >= 5_000) {
        await this._reportPendingData();
      }
    }, 1_000);
  }

  async _reportPendingData() {
    try {
      const body = { 
        container_uid: this.containerUid, 
        page_load_identifier: window.Tagsafe.pageLoadId(),
        full_page_url: window.location.href,
        page_load_ts: window.Tagsafe.pageLoadTs(), 
        ...this.dataToReport 
      };
      if(this.debugMode) {
        console.log(`Sending data to Tagsafe API`);
        console.log(body);
      }
      // await fetch(this.reportingURL, { method: 'POST', body: JSON.stringify(body) });
      const http = new XMLHttpRequest();
      http.open('POST', this.reportingURL, true);
      http.setRequestHeader('Content-type', 'application/json');
      http.send(JSON.stringify(body));

      this.dataReported.third_party_tags.concat(this.dataToReport.third_party_tags);
      this.dataReported.errors.concat(this.dataToReport.errors);
      this._flushPendingData();
    } catch (err) {
      console.error(`Tagsafe API error: ${err}`);
      this._flushPendingData();
    }
  }

  _flushPendingData() {
    this.dataToReport = { third_party_tags: [], performance_metrics: {}, intercepted_tags: [], errors: [], warnings: [] };
    this.lastReceivedDataAt = null;
  }
}