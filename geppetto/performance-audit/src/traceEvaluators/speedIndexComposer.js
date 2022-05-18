const speedline = require('speedline-core'),
        { uploadToS3 } = require('../s3');

class SpeedIndexComposer {
  constructor(tracePath, uniqueFilename) {
    this.tracePath = tracePath;
    this.uniqueFilename = uniqueFilename;
    this.maxNumFrames = parseInt(process.env.MAX_NUM_OF_SPEED_INDEX_FRAMES || '20');
  }

  gatherSpeedIndexResults = async () => {
    const speedlineResult = await this._calculateSpeedIndexFromTraceFile();
    if(speedlineResult.error_message) {
      return speedlineResult;
    } else {
      const formattedSpeedIndexData = {
        speed_index: speedlineResult.speedIndex,
        perceptual_speed_index: speedlineResult.perceptualSpeedIndex,
        recording_start_ts: speedlineResult.beginning,
        recording_end_ts: speedlineResult.end,
        ms_before_first_visual_change: speedlineResult.first,
        ms_before_last_visual_change: speedlineResult.last,
        total_recording_duration_ms: speedlineResult.duration,
        total_frames: speedlineResult.frames.length,
        frame_screenshots: await this._formatAndUploadFrameScreenshotsToS3(speedlineResult)
      };
      console.log(`Gathered Speed Index data! ${JSON.stringify(formattedSpeedIndexData)}`);
      return formattedSpeedIndexData;
    }
  }

  _calculateSpeedIndexFromTraceFile = async () => {
    try {
      console.log(`Calculating speed index, reading from Trace file ${this.tracePath}`);
      return await speedline(this.tracePath);
    } catch(err) {
      console.log(`Unable to gather Speed Index data.....${err.stack}`);
      return { error_message: err.message, error_stack: err.stack };
    }
  }

  _formatAndUploadFrameScreenshotsToS3 = async speedlineResult => {
    const formattedFrameScreenshots = [];
    const baseTs = speedlineResult.frames[0].getTimeStamp();
    for(let i = 0; i < speedlineResult.frames.length; i++) {
      const frame = speedlineResult.frames[i];
      const buffer = Buffer.from(frame.getImage());
      const s3Url = i >= this.maxNumFrames ? null : await uploadToS3({ Body: buffer, Key: `${this.uniqueFilename}-frame-${i}.png`, ACL: 'public-read' });
      formattedFrameScreenshots.push({
        ms_from_start: frame.getTimeStamp() - baseTs,
        ts: frame.getTimeStamp(),
        progress: frame.getProgress(),
        perceptual_progress: frame.getPerceptualProgress(),
        s3_url: s3Url
      })
    }
    return formattedFrameScreenshots;
  }
}

module.exports = SpeedIndexComposer;