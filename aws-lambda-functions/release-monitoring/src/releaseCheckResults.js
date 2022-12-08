const DataStoreManager = require('./dataStoreManager');

module.exports = class ReleaseChecksResults {
  constructor(releaseCheckBatchId, results) {
    this.releaseCheckBatchId = releaseCheckBatchId;
    this.results = results;
  }

  formattedResults() {
    return this.results.map(result => [
      result['tag_id'],
      this.releaseCheckBatchId,
      (result['hashed_content'] || {})['has_same_hashed_content_in_recent_version'],
      (result['bytes'] || {})['changed'],
      (result['hashed_content'] || {})['changed'],
      false, // captured_new_tag_version
      DataStoreManager.formattedTs(new Date()),
      DataStoreManager.formattedTs(new Date()),
      DataStoreManager.formattedTs(new Date())
      // result['created_at'],
      // result['updated_at'],
      // result['executed_at']
    ]) 
  }
}