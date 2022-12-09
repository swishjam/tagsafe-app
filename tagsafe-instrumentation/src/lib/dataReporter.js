export default class DataReporter {
  constructor({ reportingURL, domainUid, sampleRate = 1, debugMode = false }) {
    this.dataToReport = { new_tags: [], intercepted_tags: [], errors: [], warnings: [] };
    this.dataReported = { new_tags: [], intercepted_tags: [], errors: [], warnings: [] };
    this.lastReceivedDataAt = null;
    this.reportingURL = reportingURL;
    this.domainUid = domainUid;
    this.debugMode = debugMode;

    // sample rate of 1 means capture everything, 0 means capture nothing
    this.reportingEnabled = Math.random() < sampleRate;
    if (this.reportingEnabled) { 
      if(this.debugMode) console.log(`Reporting is enabled (sample rate is set to ${sampleRate * 100}%).`);
      this._startReportingInterval();
      window.Tagsafe.config.reportingEnabled = true;
    } else {
      if (this.debugMode) console.log(`Reporting is disabled (sample rate is set to ${sampleRate * 100}%).`);
      window.Tagsafe.config.reportingEnabled = false;
    }
  }

  recordNewTag({ tagUrl, loadType }) {
    this._recordData('new_tags', { 
      tag_url: tagUrl, 
      load_type: loadType,
      page_url_found_on: window.location.href 
    });
  }

  recordInterceptedTag(tagUrl) {
    this._recordData('intercepted_tags', { 
      tag_url: tagUrl,
      page_url_intercepted_on: window.location.href
    })
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
      const body = { domain_uid: this.domainUid, ts: new Date(), ...this.dataToReport };
      if(this.debugMode) {
        console.log(`Sending data to Tagsafe API`);
        console.log(body);
      }
      await fetch(this.reportingURL, {
        method: 'POST',
        body: JSON.stringify(body)
      })
      this.dataReported.new_tags.concat(this.dataToReport.new_tags);
      this.dataReported.errors.concat(this.dataToReport.errors);
      this._flushPendingData();
    } catch (err) {
      console.error(`Tagsafe API error: ${err}`);
      this._flushPendingData();
    }
  }

  _flushPendingData() {
    this.dataToReport = { new_tags: [], intercepted_tags: [], errors: [], warnings: [] };
    this.lastReceivedDataAt = null;
  }
}