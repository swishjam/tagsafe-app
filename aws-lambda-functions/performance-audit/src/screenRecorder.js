const { PuppeteerScreenRecorder } = require('puppeteer-screen-recorder'),
        fs = require('fs'),
        S3 = require('./s3');

class ScreenRecorder {
  constructor({ page, enabled, options }) {
    this.page = page;
    this.enabled = enabled;
    this.options = options;
    this.filename = `${this.options.filenamePrefix}-screen-recording-${parseInt(Math.random() * 100000000)}.${this.options.fileFormat || 'mp4'}`;
    this.localFilePath = `/tmp/${this.filename}`;
    this.displayInteractionHelpers = typeof this.options.displayInteractionHelpers === 'undefined' ? true : this.options.displayInteractionHelpers;
    this.throwErrorOnUnsuccessfulRecording = false
    this.isRecording = false;
  }

  msTookToStop = () => this._msTookToStop;
  recordingS3Url = () => this._recordingS3Url;
  failedRecordingErrorMessage = () => this._failedRecordingErrorMessage;

  startRecordingIfNecessary = async () => {
    if(this.enabled) {
      console.log(`Starting screen recording and saving to ${this.localFilePath}. File Format: ${this.options.fileFormat || 'webm'}. FPS: ${this.options.fps || 15}...`);
      this._initializePuppeteerScreenRecorder();
      if(this.displayInteractionHelpers) await this._setupInteractionHelpers();
      await this.recorder.start(this.localFilePath);
      this.isRecording = true;
      // await this.recorder.startStream(someWritableStream?)
    } else {
      console.log('Screen recording is disabled.');
    }
  }

  tryToStopRecordingAndUploadToS3IfNecessary = async () => {
    if(this.enabled) {
      try {
        await this._stopRecording();
        await this._uploadRecordingToS3();
      } catch(err) {
        console.error(`Unable to stop recording and upload to S3 successfully: ${err}`);
        this._failedRecordingErrorMessage = err.message;
        this._removeLocalRecordingFile();
        if(this.throwErrorOnUnsuccessfulRecording) {
          throw new Error(err);
        } else {
          console.log('Continuing anyways...');
        }
      }
    } else {
      console.log('Screen recording is disabled, skipping S3 upload process.');
    }
  }

  _uploadRecordingToS3 = async () => {
    if(this.enabled) {
      this._recordingS3Url = await S3.uploadToS3({ Body: fs.readFileSync(this.localFilePath), Key: this.filename, ACL: 'public-read' });
    }
  }

  _initializePuppeteerScreenRecorder = () => {
    console.log(`Initializing PuppeteerScreenRecorder with ffmpeg_Path = '${process.env.FFMPEG_FILEPATH}'`);
    this.recorder = this.recorder || new PuppeteerScreenRecorder(this.page, { 
      ffmpeg_Path: process.env.FFMPEG_FILEPATH,
      fps: this.options.fps || 15 
    });
  }

  _stopRecording = async () => {
    if(this.enabled) {
      let start = Date.now();
      console.log('Stopping screen recording...');
      await Promise.race([
        this.recorder.stop(),
        this._stopRecordingTimer()
      ])
      if(this._unableToStopRecordingWithinThreshold) {
        throw new Error(this._failedRecordingErrorMessage);
      } else {
        this.isRecording = false;
        this._msTookToStop = Date.now() - start;
        console.log(`Screen recording successfully stopped in ${this._msTookToStop/1_000} seconds.`);
      }
    } else {
      console.log('Screen recording is disabled, skipping stopping of recording.');
    }
  }

  _stopRecordingTimer = async () => {
    const msToStop = this.options.maxAllowableScreenRecordingStopTime || 30_000;
    return new Promise(resolve => {
      setTimeout(() => { 
        if(this.isRecording) {
          this._unableToStopRecordingWithinThreshold = true;
          this._failedRecordingErrorMessage = `Screen recording failed, unable to complete stopping of screen recording within ${msToStop/1_000} seconds.`;
          resolve();
        }
      }, msToStop);
    });
  }

  _removeLocalRecordingFile = () => {
    if(this.localFilePath && fs.existsSync(this.localFilePath)) {
      fs.unlinkSync(this.localFilePath);
      this.localFilePath = null;
    }
  }
  
  _setupInteractionHelpers = async () => {
    await this.page.evaluateOnNewDocument(() => {
      if(window !== window.parent) return;
      const box = document.createElement('puppeteer-mouse-pointer');
      const styleEl = document.createElement('style');
      styleEl.innerHTML = `
        puppeteer-mouse-pointer {
          pointer-events: none;
          position: absolute;
          top: 0;
          z-index: 10000;
          left: 0;
          width: 20px;
          height: 20px;
          background: rgba(0,0,0,.4);
          border: 1px solid white;
          border-radius: 10px;
          margin: -10px 0 0 -10px;
          padding: 0;
          transition: background .2s, border-radius .2s, border-color .2s;
        }
        puppeteer-mouse-pointer.button-1 {
          transition: none;
          background: rgba(0,0,0,0.9);
        }
        puppeteer-mouse-pointer.button-2 {
          transition: none;
          border-color: rgba(0,0,255,0.9);
        }
        puppeteer-mouse-pointer.button-3 {
          transition: none;
          border-radius: 4px;
        }
        puppeteer-mouse-pointer.button-4 {
          transition: none;
          border-color: rgba(255,0,0,0.9);
        }
        puppeteer-mouse-pointer.button-5 {
          transition: none;
          border-color: rgba(0,255,0,0.9);
        }
      `;
      function injectElementsAndStartListeners() {
        document.head.appendChild(styleEl);
        document.body.appendChild(box);
        document.addEventListener('mousemove', event => {
          box.style.left = event.pageX + 'px';
          box.style.top = event.pageY + 'px';
        }, true);
            document.addEventListener('mousedown', event => {
          updateButtons(event.buttons);
          box.classList.add('button-' + event.which);
        }, true);
        document.addEventListener('mouseup', event => {
          updateButtons(event.buttons);
          box.classList.remove('button-' + event.which);
        }, true);
        function updateButtons(buttons) {
          for (let i = 0; i < 5; i++)
            box.classList.toggle('button-' + i, buttons & (1 << i));
        }
        console.log(`Added interaction helpers to DOM`);
      }
      if(document.head && document.body) {
        injectElementsAndStartListeners();
      } else {
        let waitForHeadInterval = setInterval(() => {
          if(document.head && document.body) {
            injectElementsAndStartListeners();
            clearInterval(waitForHeadInterval);
          }
        }, 1);
      }
    })
  }
}

module.exports = ScreenRecorder;