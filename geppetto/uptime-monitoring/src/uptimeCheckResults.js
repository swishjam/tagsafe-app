const DataStoreManager = require('./dataStoreManager');

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
      DataStoreManager.formattedTs(new Date()),
      DataStoreManager.formattedTs(result.executedAtDate)
    ])
  }
}