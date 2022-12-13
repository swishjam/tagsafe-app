const fs = require('fs');

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
  constructor({ page, includeScreenshots = false, localFilePath = '/tmp/trace.json' }) {
    this.page = page;
    this.includeScreenshots = includeScreenshots;
    this.localFilePath = localFilePath;
  }

  startTracing = async () => {
    await this.page.tracing.start({ 
      path: this.localFilePath, 
      screenshots: this.includeScreenshots, 
      categories: DEFAULT_CATEGORIES 
    });
  }

  stopTracing = async () => {
    await this.page.tracing.stop();
  }

  purgeLocalFile = () => {
    fs.rmdirSync(this.localFilePath);
  }
}

module.exports = Tracer;