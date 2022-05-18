const AWS = require('aws-sdk');

const S3 = new AWS.S3({
  accessKeyId: process.env.S3_AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.S3_AWS_SECRET_ACCESS_KEY
});

module.exports = class S3ResultUploader {
  constructor({ tagUrl, checkInterval, tagId, content }) {
    this.content = content;
    this.s3Key = `int-${checkInterval}-${tagId}-${new URL(tagUrl).hostname.replace(/\\|\:|\.|\//g, '_')}-${Date.now()}`;
  }

  async uploadNewVersionToS3() {
    let start = Date.now();
    console.log(`Uploading ${this.s3Key} content into ${process.env.S3_BUCKET_NAME}`);
    // if(process.env.IS_LOCAL === 'true') {
    //   console.log('Mocking S3 upload...');
    //   fs.writeFileSync(`s3-${process.env.S3_BUCKET_NAME}-${this.s3Key}.js`, this.content);
    //   return `https://FAKE-S3-UPLOAD-${process.env.S3_BUCKET_NAME}.aws.com/fake-upload-${this.s3Key}`;
    // } else {
      const uploadParams = { Bucket: process.env.S3_BUCKET_NAME, Body: this.content, Key: `${this.s3Key}.js` };
      const result = await S3.upload(uploadParams).promise();
      console.log(`Completed S3 upload in ${(Date.now() - start) / 1000} seconds.`);
      return result.Location;
    // }
  }
}