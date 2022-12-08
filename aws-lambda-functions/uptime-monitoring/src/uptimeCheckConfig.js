module.exports = class UptimeCheckConfig {
  constructor({ tagId, tagUrl, uptimeRegionId }) {
    this.tagId = tagId;
    this.tagUrl = tagUrl;
    this.uptimeRegionId = uptimeRegionId;
  }

  setUptimeResults(uptimeResults) {
    this.responseMs = uptimeResults.responseMs;
    this.responseCode = uptimeResults.responseCode;
    this.executedAtDate = uptimeResults.executedAtDate;
  }
}