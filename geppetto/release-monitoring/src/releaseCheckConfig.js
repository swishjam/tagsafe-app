module.exports = class ReleaseCheckConfig {
  constructor({ jsonConfig, minuteInterval }) {
    this.jsonConfig = jsonConfig;
    this.minuteInterval = minuteInterval || 0;
  }

  get asJson() {
    return this.jsonConfig;
  }

  get tagId() {
    return this.jsonConfig['tag_id'] || new Error(`ReleaseConfig is missing \`tag_id\` property: ${JSON.stringify(this.asJson)}`)
  }

  get tagUrl() {
    return this.jsonConfig['tag_url'] || new Error(`ReleaseConfig is missing \`tag_url\` property: ${JSON.stringify(this.asJson)}`);
  }

  get shouldCheckForNewRelease() {
    return !this.isPendingTagVersionCapture
  }

  get isPendingTagVersionCapture() {
    return this.jsonConfig['marked_as_pending_tag_version_capture_at'] !== null;
  }

  get currentVersionHashedContent() {
    return this.jsonConfig['current_hashed_content'];
  }

  get recentHashedContent() {
    if(!this.jsonConfig['recent_hashed_content']) {
      const tenMostRecentHashedContent = JSON.parse(this.jsonConfig['ten_most_recent_hashed_content'] || '[]');
      if(tenMostRecentHashedContent.length > this.numRecentTagVersionsToCompare) {
        tenMostRecentHashedContent.splice(this.numRecentTagVersionsToCompare);
      }
      this.jsonConfig['recent_hashed_content'] = tenMostRecentHashedContent;
    }
    return this.jsonConfig['recent_hashed_content'];
  }

  get currentVersionBytes() {
    return this.jsonConfig['current_version_bytes_size'];
  }

  get numRecentTagVersionsToCompare() {
    return this.jsonConfig['num_recent_tag_versions_to_compare_in_release_monitoring'] || 5;
  }
}