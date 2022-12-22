const TraceParser = require('lighthouse/lighthouse-core/lib/tracehouse/trace-processor');
const MainThreadTasks = require('lighthouse/lighthouse-core/lib/tracehouse/main-thread-tasks');
const fs = require('fs');

class MainThreadAnalyzer {
  constructor(traceFilePath) {
    this.traceFilePath = traceFilePath;
  }

  get parsedTrace() {
    if (this._parsedTrace) return this._parsedTrace;
    console.log(`Parsing trace file from ${this.traceFilePath}`);
    let rawTrace = JSON.parse(fs.readFileSync(this.traceFilePath));
    if (!rawTrace.traceEvents) rawTrace = { traceEvents: rawTrace };
    return this._parsedTrace = TraceParser.processTrace(rawTrace);
  }

  get mainThreadTasks() {
    if (this._mainThreadTasks) return this._mainThreadTasks;
    console.log(`Gathering all main thread tasks`);
    return this._mainThreadTasks = MainThreadTasks.getMainThreadTasks(
      this.parsedTrace.mainThreadEvents,
      this.parsedTrace.frames,
      this.parsedTrace.timestamps.traceEnd
    )
  }

  mainThreadExecutionForUrl = (urlPatterns, msToConsiderBlocking = 50) => {
    urlPatterns = typeof urlPatterns === 'string' ? [urlPatterns] : urlPatterns;
    console.log(`Calculating main thread execution time and blocking tasks for ${JSON.stringify(urlPatterns)}`);
    if (!fs.existsSync(this.traceFilePath)) throw new Error(`Cannot calculate Main Thread Tasks, provided file (${this.traceFilePath}) does not exist.`);
    let allMainThreadExecutionsMs = 0;
    let allMainThreadBlockingExecutionMs = 0;
    let totalExecutionMsForUrlPatterns = 0;
    let totalMainThreadBlockingMsForUrlPatterns = 0;
    let longTasksForUrlPatterns = [];
    // let totalExecutionMsByTag = {};
    // let blockingExecutionMsByTag = {};
    this.mainThreadTasks.forEach(task => {
      allMainThreadExecutionsMs += task.selfTime;
      if (task.selfTime >= msToConsiderBlocking) allMainThreadBlockingExecutionMs += task.selfTime;
      if (this._taskIsAttributableToUrlPatterns(task, urlPatterns)) {
        totalExecutionMsForUrlPatterns += task.selfTime;
        if (task.selfTime >= msToConsiderBlocking) {
          totalMainThreadBlockingMsForUrlPatterns += task.selfTime;
          longTasksForUrlPatterns.push(this._formattedTask(task));
        }
      }
    })
    return {
      allMainThreadExecutionsMs,
      allMainThreadBlockingExecutionMs,
      totalExecutionMsForUrlPatterns,
      totalMainThreadBlockingMsForUrlPatterns,
      longTasksForUrlPatterns
    };
  }

  parseMainThreadActivityByUrl() {
    
  }

  _formattedTask = task => {
    return {
      duration: task.duration,
      selfTime: task.selfTime,
      startTime: task.startTime,
      endTime: task.endTime,
      event: task.event,
      group: task.group,
      attributableURLs: task.attributableURLs
    };
  }

  _taskIsAttributableToUrlPatterns = (task, urlPatterns) => {
    return typeof task.attributableURLs.find(
      attributableUrl => urlPatterns.find(
        urlPattern => attributableUrl.includes(urlPattern)
      )
    ) === 'string'
  }
}

module.exports = MainThreadAnalyzer;