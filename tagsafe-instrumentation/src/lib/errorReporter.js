export class ErrorReporter {
  constructor({ reportingURL, containerUid = null }) {
    this.reportingURL = reportingURL;
    this.containerUid = containerUid;
  }

  reportError = (errMsg) => {
    const http = new XMLHttpRequest();
    http.open('POST', this.reportingURL, true);
    http.send(JSON.stringify({
      container_uid: this.containerUid,
      tagsafe_consumer_resque_queue: 'tagsafe_js_events',
      tagsafe_consumer_resque_klass: 'TagsafeJsDataConsumerJob',
      is_error_report: true,
      errors: [errMsg],
    }));
  }
}