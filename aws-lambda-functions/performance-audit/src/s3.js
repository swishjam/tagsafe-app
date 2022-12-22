const AWS = require('aws-sdk'),
      fs = require('fs');

const S3 = new AWS.S3({
  accessKeyId: process.env.S3_AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.S3_AWS_SECRET_ACCESS_KEY
});

const uploadToS3 = async ({ Body, Key, Bucket = process.env.S3_BUCKET_NAME.trim(), ACL = undefined }) => {
  return new Promise((resolve, reject) => {
    let start = Date.now();
    console.log(`Uploading ${Key} content into ${Bucket}`);
    if(process.env.MOCK_S3_UPLOADS === 'true') {
      console.log('Mocking S3 upload...');
      fs.writeFileSync(`s3-${Bucket}-${Key}`, Body);
      resolve(`https://s3-${Bucket}.aws.com/fake-upload-${Key}`);
    } else {
      let uploadParams = { Bucket: Bucket, Body: Body, Key: Key };
      if(ACL) uploadParams['ACL'] = ACL;
      S3.upload(uploadParams, (err, data) => {
        if(err) {
          reject(err);
        } else {
          console.log(`Completed S3 upload in ${(Date.now() - start)/1000} seconds.`);
          resolve(data.Location);
        }
      });
    }
  })
}

const getObject = async key => {
  return new Promise((resolve, reject) => {
    let start = Date.now();
    console.log(`Fetching ${key} from ${process.env.S3_BUCKET_NAME}...`);
    S3.getObject({ Bucket: process.env.S3_BUCKET_NAME.trim(), Key: key }, (err, data) => {
      if(err) {
        reject(err);
      } else {
        console.log(`Got ${key} in ${(Date.now() - start)/1000} seconds.`);
        resolve(data.Body);
      }
    });
  })
}

module.exports = { 
  uploadToS3: uploadToS3,
  getObject: getObject
}