const { PuppeteerScreenRecorder } = require('puppeteer-screen-recorder'),
        fs = require('fs'),
        AWS = require('aws-sdk');

const S3 = new AWS.S3({
  accessKeyId: process.env.S3_AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.S3_AWS_SECRET_ACCESS_KEY
});

class ScreenRecorder {
  constructor({ enabled, millisecondsLeftFunction, options = {} }) {
    this.enabled = enabled;
    this.millisecondsLeftFunction = millisecondsLeftFunction;
    this.options = options;
    this.filename = `${this.options['filenamePrefix']}-screen-recording-${parseInt(Math.random() * 100000000)}.${this.options['fileFormat'] || 'mp4'}`;
    this.localFilePath = `/tmp/${this.filename}`;
    this.throwErrorOnUnsuccessfulRecording = false
    this.isRecording = false;
    
    this.msTookToStop;
    this.s3Url;
  }

  startRecordingIfNecessary = async page => {
    if(this.enabled) {
      console.log(`Starting screen recording. File Format: ${this.options['fileFormat'] || 'webm'}. FPS: ${this.options['fps'] || 15}...`);
      this._initializePuppeteerScreenRecorder(page);
      await this.recorder.start(this.localFilePath);
      this.isRecording = true;
      console.log(`Recorder is now recording!`)
    } else {
      console.log('Screen recording is disabled, not going to record.');
    }
  }

  tryToStopRecordingAndUploadToS3IfNecessary = async () => {
    return new Promise((resolve, reject) => {
      if(this.enabled && this.recorder) {
        this._stopRecordingWithinThreshold().then(() => {
          this._uploadRecordingToS3().then(resolve);
        }).catch(err => {
          console.error(`Unable to stop recording and upload to S3 successfully: ${err}`);
          if(this.throwErrorOnUnsuccessfulRecording) {
            reject(new Error(err));
          } else {
            console.log('Continuing anyways...');
            resolve();
          }
        })
      } else {
        console.log('Screen recording is disabled or never initialized, skipping S3 upload process.');
        resolve();
      }
    })
  }

  _uploadRecordingToS3 = async () => {
    return new Promise((resolve, reject) => {
      if(this.enabled) {
        if(!this.s3Url) {
          let start = Date.now();
          console.log(`Uploading screen recording ${this.filename} content into ${process.env.S3_BUCKET_NAME}`);
          if(process.env.MOCK_S3_UPLOAD === 'true') {
            console.log('S3 uploads are disabled, mocking upload....');
            fs.writeFileSync(this.filename, fs.readFileSync(this.localFilePath))
            this.s3Url = `https://s3.aws.com/mock-upload-${this.filename}`;
            resolve(this.s3Url);
          } else {
            S3.upload({ Bucket: process.env.S3_BUCKET_NAME, Body: fs.readFileSync(this.localFilePath), Key: this.filename, ACL: 'public-read' }, (err, data) => {
              if(err) {
                console.error(`Error enounctered in S3 upload: ${JSON.stringify(err)}`);
                reject(err);
              } else {
                console.log(`Upload completed in ${(Date.now() - start)/1000} seconds!`);
                this.s3Url = data.Location;
                resolve(this.s3Url);
              }
            });
          }
        } else {
          console.log(`Already uploaded ${this.filename} to s3 during this script run, skipping...`);
        }
      } else {
        console.log('Screen recording is disabled, skipping S3 upload');
        resolve();
      }
    })
  }

  _initializePuppeteerScreenRecorder = page => {
    this.recorder = this.recorder || new PuppeteerScreenRecorder(page, { 
      ffmpeg_Path: process.env.FFMPEG_FILEPATH,
      fps: this.options['fps'] || 15 
    });
  }

  _stopRecordingWithinThreshold = async () => {
    return new Promise(async (resolve, reject) => {
      if(!this.enabled) {
        console.log('Screen recording is disabled, skipping stopping of recording.');
        resolve();
      } else if(!this.isRecording) {
        console.log('Recorder is not recording therefore skipping stopping of recording...');
        resolve();
      } else {
        let startTime = Date.now();
        console.log('Stopping screen recording...');
        await Promise.race([
          this.recorder.stop(),
          this._setTimeoutToThrowErrorIfRecordingDoesntStopWithinThreshold()
        ]);
        this.isRecording = false;
        if(this.failedToStop) {
          reject(new Error(`Failed to stop recording within ${this.msAvailableToStopRecording/1_000} seconds.`));
        } else {
          this.msTookToStop = Date.now() - startTime;
          console.log(`Screen recording successfully stopped in ${this.msTookToStop/1_000} seconds.`);
          resolve();
        }
      }
    })
  }

  _setTimeoutToThrowErrorIfRecordingDoesntStopWithinThreshold = async () => {
    return new Promise(resolve => {
      const bufferMs = parseInt(process.env.STOP_RECORDING_BUFFER_MS_FROM_LAMBDA_TIMEOUT || 10_000);
      this.msAvailableToStopRecording = this.millisecondsLeftFunction() - bufferMs;
      console.log(`Going to stop trying to stop recording after ${this.msAvailableToStopRecording/1_000} seconds, ${bufferMs/1_000} seconds before Lambda times out.`);
      setTimeout(() => {
        if(this.isRecording) {
          console.error(`Screen recording failed, unable to complete stopping of screen recording within ${this.msAvailableToStopRecording/1_000} seconds.`);
          this.failedToStop = true;
          resolve();
        }
      }, this.msAvailableToStopRecording);
    })
  }
}

module.exports = ScreenRecorder;