const calcLambdaCost = require('./lambdaCostCalcaultor'),
      ReleaseDetector = require('./releaseDetector'),
      S3ResultUploader = require('./s3ResultUploader');

module.exports = class ReleaseCheckerRunner {
  constructor({ releaseCheckConfig, dataStoreManager, resultsWithNewVersionsArray, resultsWithoutNewVersionsArray, tagEvent, span }) {
    this.releaseCheckConfig = releaseCheckConfig;
    this.dataStoreManager = dataStoreManager;
    this.resultsWithNewVersions = resultsWithNewVersionsArray;
    this.resultsWithoutNewVersions = resultsWithoutNewVersionsArray;
    this.tagEvent = tagEvent;
    this.span = span;

    this.releaseDetector = new ReleaseDetector(releaseCheckConfig);
    this.startTs = Date.now()
  }

  async runReleaseCheck() {
    await this.span(`release-check-${this.releaseCheckConfig.tagUrl}`, async () => {
      this.tagEvent('release-check-tag-id', this.releaseCheckConfig.tagId);
      this.tagEvent('release-check-tag-url', this.releaseCheckConfig.tagUrl);
      this.releaseCheckResult = await this.releaseDetector.checkForRelease();
      if(this.releaseDetector.foundNewVersion()) {
        await this._onReleaseDetected();
      } else {
        this._onReleaseNotDetected();
      }
    })
  }

  async _onReleaseDetected() {
    console.log(`${this.releaseCheckConfig.tagUrl} has a new version!`);
    console.log(JSON.stringify(this.releaseCheckResult));
    await this.dataStoreManager.markTagAsPendingTagVersionCapture(this.releaseCheckConfig.tagId);
    const newVersionS3Url = await this._uploadNewTagVersionContentToS3();
    this.releaseCheckResult['new_version_s3_url'] = newVersionS3Url;
    this.releaseCheckResult['ms_to_complete'] = Date.now() - this.startTs;
    this.releaseCheckResult['estimated_lambda_cost'] = calcLambdaCost(this.releaseCheckResult['ms_to_complete']);
    this.resultsWithNewVersions.push(this.releaseCheckResult);
  }

  _onReleaseNotDetected() {
    console.log(`${this.releaseCheckConfig.tagUrl} has not released a new version.`);
    this.releaseCheckResult['ms_to_complete'] = Date.now() - this.startTs;
    this.releaseCheckResult['estimated_lambda_cost'] = calcLambdaCost(this.releaseCheckResult['ms_to_complete']);
    this.resultsWithoutNewVersions.push(this.releaseCheckResult);
  }

  async _uploadNewTagVersionContentToS3() {
    const uploader = new S3ResultUploader({
      checkInterval: this.releaseCheckConfig.minuteInterval,
      tagUrl: this.releaseCheckConfig.tagUrl,
      tagId: this.releaseCheckConfig.tagId,
      content: this.releaseDetector.fetchedContent
    });
    return await uploader.uploadNewVersionToS3();
  }
}