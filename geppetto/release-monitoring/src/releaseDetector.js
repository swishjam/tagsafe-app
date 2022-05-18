const fetch = require('node-fetch'),
        crypto = require('crypto');

module.exports = class ReleaseDetector {
  constructor(releaseConfig) {
    this.releaseConfig = releaseConfig;
  }

  get fetchedContent() {
    if(!this.checkedForRelease) {
      throw new Error('Must call `checkForRelease` before accessing `fetchedContent`');
    } else {
      return this.currentContent;
    }
  }

  async checkForRelease() {
    await this._fetchCurrentContent();
    const results = {
      tag_id: this.releaseConfig.tagId,
      ts: Date.now(),
      human_ts: new Date().toLocaleString(),
      read_config: this.releaseConfig.asJson,
      should_check_for_new_release: this.releaseConfig.shouldCheckForNewRelease,
      found_new_version: false
    }
    if(this.releaseConfig.shouldCheckForNewRelease) {
      results['hashed_content'] = {
        changed: await this._hashedContentChanged(),
        new_hashed_content: await this._fetchedHashedContent(),
        previous_hashed_content: this.releaseConfig.currentVersionHashedContent,
        has_same_hashed_content_in_recent_version: await this._contentIsTheSameAsARecentVersion()
      };
      results['bytes'] = {
        changed: await this._byteSizeChanged(),
        new_byte_size: this.newByteSize,
        previous_byte_size: this.releaseConfig.currentVersionBytes
      };
    } else {
      console.log('Not checking for new release because this Tag is pending capture of a new tag version from Tagsafe.')
    }
    this.checkedForRelease = true;
    results['found_new_version'] = this.foundNewVersion();
    return results;
  }

  foundNewVersion() {
    if(!this.checkedForRelease) {
      throw new Error('`foundNewVersion` called before `checkForRelease` was run.')
    } else if(this.releaseConfig.shouldCheckForNewRelease){
      return this.hashedContentChanged === true && this.byteSizeChanged === true && this.contentIsTheSameAsARecentVersion === false;
    }
  }

  async _fetchedHashedContent() {
    if(!this.fetchedHashedContent) {
      const content = await this._fetchCurrentContent();
      this.fetchedHashedContent = this._md5(content);
    }
    return this.fetchedHashedContent;
  }

  async _hashedContentChanged() {
    if(!this.hashedContentChanged) {
      this.hashedContentChanged = this.releaseConfig.currentVersionHashedContent !== await this._fetchedHashedContent();
    }
    return this.hashedContentChanged;
  }

  async _byteSizeChanged() {
    if(!this.byteSizeChanged) {
      const content = await this._fetchCurrentContent();
      this.newByteSize = Buffer.byteLength(content);
      this.byteSizeChanged = this.newByteSize !== this.releaseConfig.currentVersionBytes
    }
    return this.byteSizeChanged;
  }

  async _contentIsTheSameAsARecentVersion() {
    if(!this.contentIsTheSameAsARecentVersion) {
      this.contentIsTheSameAsARecentVersion = this.releaseConfig.recentHashedContent.includes(await this._fetchedHashedContent());
    }
    return this.contentIsTheSameAsARecentVersion
  }

  async _fetchCurrentContent() {
    if(!this.currentContent) {
      console.log(`\n\nChecking ${this.releaseConfig.tagUrl} for new release...`);
      const response = await fetch(this.releaseConfig.tagUrl);
      this.currentContent = await response.text();
    }
    return this.currentContent;
  }

  _md5(string) {
    return crypto.createHash('md5').update(string).digest('hex');
  }
}