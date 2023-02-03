const PuppeteerModerator = require('./puppeteerModerator');
const AWS = require('aws-sdk');

require('dotenv').config();

module.exports = class TagHoster {
  constructor({ pageUrl, firstPartyHosts }) {
    this.pageUrl = pageUrl;
    this.firstPartyHosts = firstPartyHosts;
  }

  async findAllThirdPartyTagsAndUploadThemToS3() {
    console.log(`Finding all third-party tags on ${this.pageUrl}...`);
    const tagUrls = await this._getThirdPartyTagUrlsOnPage();
    return await this._uploadThirdPartyTagsToS3(tagUrls);
  }

  async _getThirdPartyTagUrlsOnPage() {
    console.log(`Navigating to ${this.pageUrl}...`);
    const puppeteerModerator = new PuppeteerModerator();
    const page = await puppeteerModerator.launch();

    let thirdPartyTagsUrls = [];

    await page.setRequestInterception(true);
    page.on('request', async req => {
      if (req.resourceType() === 'script' && !this.firstPartyHosts.includes(new URL(req.url()).host)) {
        console.log(`Found third-party tag: ${req.url()}`);
        thirdPartyTagsUrls.push(req.url());
      }
      await req.continue();
    })

    await page.goto(this.pageUrl, { waituntil: ['domcontentloaded', 'networkidle2'] });
    await puppeteerModerator.shutdown();
    return thirdPartyTagsUrls;
  }

  async _uploadThirdPartyTagsToS3(tagUrls) {
    console.log(`Uploading third-party tags to S3...`);
    const s3 = new AWS.S3();
    const Bucket = process.env.S3_BUCKET_NAME;
    const bucketParams = { Bucket, ACL: 'public-read' };

    const s3Dir = this.pageUrl.replace(/[^a-zA-Z0-9]/g, '_');

    const s3UploadPromises = tagUrls.map(async tagUrl => {
      const tagResponse = await fetch(tagUrl);
      const tagContents = await tagResponse.text();
      const tagKey = tagUrl.replace(/[^a-zA-Z0-9]/g, '_');
      const s3Params = { ...bucketParams, Key: `tagsafe-savings-test/${s3Dir}/${tagKey}.js`, Body: tagContents };
      await s3.upload(s3Params).promise();
      
      let returnedObject = {};
      console.log(`Uploaded third-party tag to S3: ${tagUrl} -> https://${process.env.CDN_HOST}/tagsafe-savings-test/${s3Dir}/${tagKey}.js`);
      returnedObject[tagUrl] = `https://${process.env.CDN_HOST}/tagsafe-savings-test/${s3Dir}/${tagKey}.js`;
      return returnedObject
    });

    const results = await Promise.all(s3UploadPromises);
    let resultsAsObject = {};
    results.forEach(result => resultsAsObject = {...resultsAsObject, ...result});
    return resultsAsObject;
  }
}