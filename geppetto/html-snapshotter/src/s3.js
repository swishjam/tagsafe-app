const AWS = require('aws-sdk')
        fs = require('fs');

const S3 = new AWS.S3({
  accessKeyId: process.env.S3_AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.S3_AWS_SECRET_ACCESS_KEY
});

const uploadToS3 = async (content, filename, publicAcl = false) => {
  return new Promise((resolve, reject) => {
    console.log(`Uploading ${filename} content into ${process.env.S3_BUCKET_NAME}`);
    let s3Args = { Bucket: process.env.S3_BUCKET_NAME, Body: content, Key: filename };
    if(publicAcl) s3Args.ACL = 'public-read';
    if(process.env.MOCK_S3_UPLOADS === 'true') {
      console.log('Mocking S3 upload, writing it locally instead...');
      fs.writeFileSync(filename, content);
      resolve(`https://s3.aws.com/fake-upload-${filename}`);
    } else {
      let start = Date.now();
      S3.upload(s3Args, (err, data) => {
        if(err) {
          console.error(`Error enounctered in S3 upload: ${JSON.stringify(err)}`);
          reject(err);
        } else {
          console.log(`Upload to S3 ${data.Location} in ${(Date.now() - start)/1000} seconds!`);
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
    S3.getObject({ Bucket: process.env.S3_BUCKET_NAME, Key: key }, (err, data) => {
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