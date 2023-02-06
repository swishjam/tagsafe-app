const PuppeteerModerator = require('./puppeteerModerator');
const UglifyJS = require('uglify-js');
const AWS = require('aws-sdk');

require('dotenv').config();

module.exports = class TagHoster {
  constructor({ pageUrl, firstPartyHosts }) {
    this.pageUrl = pageUrl;
    this.firstPartyHosts = firstPartyHosts;
    this.s3Client = new AWS.S3();
    this.s3Directory = `tagsafe-savings-test/${this.pageUrl.replace(/[^a-zA-Z0-9]/g, '_')}`;
    this.bytesSaved = 0;
    this.totalOgByteSize = 0;
    this.totalMinifiedByteSize = 0;
    this.uploadedS3Keys = [];
  }

  async findAllThirdPartyTagsAndUploadThemToS3() {
    console.log(`Finding all third-party tags on ${this.pageUrl}...`);
    console.log(`Navigating to ${this.pageUrl}...`);
    const puppeteerModerator = new PuppeteerModerator();
    const page = await puppeteerModerator.launch();
    
    let thirdPartyTagUrls = [];
    await page.setRequestInterception(true);
    page.on('request', async req => {
      if (req.resourceType() === 'script' && !this.firstPartyHosts.includes(new URL(req.url()).host)) {
        thirdPartyTagUrls.push(req.url());
      }
      await req.continue();
    })

    await page.goto(this.pageUrl, { waituntil: ['domcontentloaded', 'networkidle0'] });
    // sleep for 5 seconds
    await new Promise(resolve => setTimeout(resolve, 5000));
    await puppeteerModerator.shutdown();

    console.log(`Uploading ${thirdPartyTagUrls.length} third-party tags to S3...`);
    let tagUrlsToTagsafeCDNMap = {};
    for(let i in thirdPartyTagUrls) {
      const tagUrl = thirdPartyTagUrls[i];
      const cdnUrl = await this._uploadThirdPartyTagsToS3(tagUrl);
      if (cdnUrl) {
        tagUrlsToTagsafeCDNMap[tagUrl] = cdnUrl;
      }
    }
    console.log(`FOUND ALL THIRD PARTY TAGS AND UPLOADED THEM TO S3! TOTAL BYTES SAVED: ${this.totalOgByteSize - this.totalMinifiedByteSize} (${(this.totalOgByteSize - this.totalMinifiedByteSize) / this.totalOgByteSize * 100}%)`);
    return { 
      tagUrlsToTagsafeCDNMap,
      totalOriginalByteSize: this.totalOgByteSize,
      totalMinifiedByteSize: this.totalMinifiedByteSize,
    };
  }

  async purgeUploadedThirdPartyTagsFromS3() {
    console.log(`Purging all third-party tags from S3...`);
    const params = { 
      Bucket: process.env.S3_BUCKET_NAME, 
      Delete: { Objects: this.uploadedS3Keys.map(key => ({ Key: key })) }
    };
    await this.s3Client.deleteObjects(params).promise();
    console.log('Purge complete!');
  }

  async _uploadThirdPartyTagsToS3(tagUrl) {
    try {
      console.log(`Uploading third-party tag to S3 ${tagUrl}...`);
      const bucketParams = { Bucket: process.env.S3_BUCKET_NAME, ACL: 'public-read' };
  
      const tagResponse = await fetch(tagUrl);
      const tagContents = await tagResponse.text();
      const ogByteSize = Buffer.byteLength(tagContents, 'utf8');
      const minifiedTagContents = UglifyJS.minify(tagContents).code;
      const minifiedByteSize = Buffer.byteLength(minifiedTagContents, 'utf8');

      this.totalOgByteSize += ogByteSize;
      this.totalMinifiedByteSize += minifiedByteSize;
  
      const tagKey = tagUrl.replace(/[^a-zA-Z0-9]/g, '_');
      const s3Params = { 
        ...bucketParams, 
        Key: `${this.s3Directory}/${tagKey}.js`, 
        Body: minifiedTagContents || tagContents, 
        ContentType: 'application/javascript' 
      };
      await this.s3Client.upload(s3Params).promise();
      this.uploadedS3Keys.push(s3Params.Key);
      return `https://${process.env.CDN_HOST}/${s3Params.Key}`;
    } catch(err) {
      console.error(`Cant upload third-party tag to S3 ${tagUrl}: ${err.message}...`)
    }
  }
}