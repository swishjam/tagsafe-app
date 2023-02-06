const PuppeteerModerator = require('./puppeteerModerator');
const UglifyJS = require('uglify-js');
const AWS = require('aws-sdk');

require('dotenv').config();

module.exports = class TagHoster {
  constructor({ pageUrl, firstPartyHosts, hostAllResources = false }) {
    this.pageUrl = pageUrl;
    this.firstPartyHosts = firstPartyHosts;
    this.hostAllResources = hostAllResources;
    this.ignoreQueryParamsWhenOverridingRequests = true;

    this.s3Client = new AWS.S3();
    this.s3Directory = `tagsafe-savings-test/${this.pageUrl.replace(/[^a-zA-Z0-9]/g, '_')}`;
    // this.bytesSaved = 0;
    // this.totalOgByteSize = 0;
    // this.totalMinifiedByteSize = 0;
    this.uploadedS3Keys = [];
  }

  async findAllThirdPartyTagsAndUploadThemToS3() {
    console.log(`Finding all resources to host on ${this.pageUrl}...`);
    console.log(`Navigating to ${this.pageUrl}...`);
    const puppeteerModerator = new PuppeteerModerator();
    const page = await puppeteerModerator.launch();
    
    let resourcesToHost = [];
    await page.setRequestInterception(true);
    page.on('request', async req => {
      if(this.hostAllResources) {
        if(req.resourceType() !== 'document') {
          resourcesToHost.push({ url: req.url(), resourceType: req.resourceType() });
        }
      } else if (req.resourceType() === 'script' && !this.firstPartyHosts.includes(new URL(req.url()).host)) {
        resourcesToHost.push({ url: req.url(), resourceType: req.resourceType() });
      }
      await req.continue();
    })

    await page.goto(this.pageUrl, { waituntil: ['domcontentloaded', 'networkidle0'] });
    await new Promise(resolve => setTimeout(resolve, 5000));
    await puppeteerModerator.shutdown();

    console.log(`Uploading ${resourcesToHost.length} resources to S3...`);
    let resourceUrlsToTagsafeCDNMap = {};
    for (let i in resourcesToHost) {
      const resource = resourcesToHost[i];
      const cdnUrl = await this._uploadResourceToS3(resource.url, resource.resourceType);
      if (cdnUrl) {
        const parsedUrl = new URL(resource.url);
        const urlWithoutQueryParams = `${parsedUrl.protocol}//${parsedUrl.host}${parsedUrl.pathname}`;
        resourceUrlsToTagsafeCDNMap[resource.url] = cdnUrl;
        resourceUrlsToTagsafeCDNMap[urlWithoutQueryParams] = cdnUrl;
      }
    }
    console.log(`FOUND ALL THIRD PARTY TAGS AND UPLOADED THEM TO S3! TOTAL BYTES SAVED: ${this.totalOgByteSize - this.totalMinifiedByteSize} (${(this.totalOgByteSize - this.totalMinifiedByteSize) / this.totalOgByteSize * 100}%)`);
    return { 
      resourceUrlsToTagsafeCDNMap,
      // totalOriginalByteSize: this.totalOgByteSize,
      // totalMinifiedByteSize: this.totalMinifiedByteSize,
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

  async _uploadResourceToS3(resourceUrl, resourceType, attempts = 0) {
    try {
      console.log(`Uploading resource to S3 ${resourceUrl}...`);
      const bucketParams = { Bucket: process.env.S3_BUCKET_NAME, ACL: 'public-read' };
  
      const resourceResponse = await fetch(resourceUrl, { headers: { 'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' }});
      const resourceContents = await resourceResponse.text();
      // if(resourceType === 'script') {
      //   const ogByteSize = Buffer.byteLength(resourceContents, 'utf8');
      //   const minifiedTagContents = UglifyJS.minify(resourceContents).code;
      //   const minifiedByteSize = Buffer.byteLength(minifiedTagContents, 'utf8');
  
      //   this.totalOgByteSize += ogByteSize;
      //   this.totalMinifiedByteSize += minifiedByteSize;
      // }
  
      const resourceKey = resourceUrl.replace(/[^a-zA-Z0-9]/g, '_');
      const contentType = {
        'script': 'application/javascript',
        'image': 'image/png',
        'stylesheet': 'text/css',
        'font': 'font/woff2',
      }[resourceType];
      const s3Params = { 
        ...bucketParams, 
        Key: `${this.s3Directory}/${resourceKey}.js`, 
        Body: resourceContents, 
        ContentType: contentType
      };
      await this.s3Client.upload(s3Params).promise();
      this.uploadedS3Keys.push(s3Params.Key);
      console.log(`Uploaded ${resourceUrl} resource to S3!`);
      return `https://${process.env.CDN_HOST}/${s3Params.Key}`;
    } catch(err) {
      console.error(`Failed to upload resource to S3 ${resourceUrl}: ${err.message}, trying again...`);
      if (attempts < 3) {
        return this._uploadResourceToS3(resourceUrl, resourceType, attempts + 1);
      } else {
        console.error(`Cant upload resource to S3 ${resourceUrl}: ${err.message}, giving up...`);
        return null;
      }
    }
  }
}