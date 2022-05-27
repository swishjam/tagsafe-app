const s3 = require('../s3'),
      fs = require('fs');

const DEFAULT_CATEGORIES = [
  // Exclude default categories. We'll be selective to minimize trace size
  '-*',

  // Used instead of 'toplevel' in Chrome 71+
  'disabled-by-default-lighthouse',

  // Used for Cumulative Layout Shift metric
  'loading',

  // All compile/execute events are captured by parent events in devtools.timeline..
  // But the v8 category provides some nice context for only <0.5% of the trace size
  'v8',
  // Same situation here. This category is there for RunMicrotasks only, but with other teams
  // accidentally excluding microtasks, we don't want to assume a parent event will always exist
  'v8.execute',

  // For extracting UserTiming marks/measures
  'blink.user_timing',

  // Not mandatory but not used much
  'blink.console',

  // Most of the events we need are from these two categories
  'devtools.timeline',
  'disabled-by-default-devtools.timeline',

  // Up to 450 (https://goo.gl/rBfhn4) JPGs added to the trace
  'disabled-by-default-devtools.screenshot',

  // This doesn't add its own events, but adds a `stackTrace` property to devtools.timeline events
  'disabled-by-default-devtools.timeline.stack',

  // Additional categories used by devtools. Not used by Lighthouse, but included to facilitate
  // loading traces from Lighthouse into the Performance panel.
  'disabled-by-default-devtools.timeline.frame',
  'latencyInfo',

  // A bug introduced in M92 causes these categories to crash targets on Linux.
  // See https://github.com/GoogleChrome/lighthouse/issues/12835 for full investigation.
  // 'disabled-by-default-v8.cpu_profiler',
];

class Tracer {
  constructor({ page, cdpSession, enabled, filename }) {
    this.page = page;
    this.cdpSession = cdpSession;
    this.enabled = enabled;
    this.filename = `tracing-${filename}-${parseInt(Math.random()*100000000)}`;
    this.localFilePath = `/tmp/${this.filename}.json`;
  }

  s3Url = () => this._s3Url;

  startTracingIfNecessary = async () => {
    if(this.enabled) {
      console.log(`Starting performance tracing...`);
      await this.page.tracing.start({ path: this.localFilePath, screenshots: true, categories: DEFAULT_CATEGORIES });

    } else {
      console.log('Tracing is disabled')
    }
  }

  stopTracing = async () => {
    if(!this.enabled) return;
    console.log('Stopping tracing...');
    await this.page.tracing.stop();
  }

  uploadToS3 = async () => {
    if(!this.enabled) return;
    console.log('Uploading trace file to S3...');
    return this._s3Url = await s3.uploadToS3({ Body: fs.readFileSync(this.localFilePath), Key: `${this.filename}.json`, ACL: 'public-read' });
  }

  purgeLocalFile = () => {
    fs.rmdirSync(this.localFilePath);
  }
}

module.exports = Tracer;