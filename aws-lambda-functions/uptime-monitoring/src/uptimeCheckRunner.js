const fetch = require('node-fetch');

module.exports = class UptimeCheckRunner {
  constructor({ uptimeCheckConfig, tagEvent, span }) {
    this.uptimeCheckConfig = uptimeCheckConfig;
    this.tagEvent = tagEvent;
    this.span = span;
  }

  async runUptimeCheck() {
    return await this.span(`uptime-check-${this.uptimeCheckConfig.tagUrl}`, async () => {
      this.tagEvent('uptime-check-tag-id', this.uptimeCheckConfig.tagId);
      this.tagEvent('uptime-check-tag-url', this.uptimeCheckConfig.tagUrl);
      return await this._measureUptime();
    })
  }

  async _measureUptime() {
    const executedAtDate = new Date();
    const response = await fetch(this.uptimeCheckConfig.tagUrl);
    return this.uptimeCheckConfig.setUptimeResults({
      executedAtDate: executedAtDate,
      responseMs: new Date() - executedAtDate,
      responseCode: response.status
    })
  }
}