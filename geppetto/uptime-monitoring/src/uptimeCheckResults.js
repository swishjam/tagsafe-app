const moment = require('moment');

module.exports = class UptimeCheckResults {
  constructor(uptimeBatchId, results) {
    this.uptimeBatchId = uptimeBatchId;
    this.results = results;
  }

  formattedForInsert() {
    return this.formattedResults = this.formattedResults || this.results.map(result =>  [
      result.tagId,
      this.uptimeBatchId,
      result.uptimeRegionId,
      result.responseMs,
      result.responseCode,
      moment.utc(new Date()).format('YYYY-MM-DD HH:mm:ss'),
      moment.utc(result.executedAtDate).format('YYYY-MM-DD HH:mm:ss')
    ])
  }
}