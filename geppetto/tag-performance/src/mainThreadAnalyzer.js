const TraceParser = require('lighthouse/lighthouse-core/lib/tracehouse/trace-processor'),
        MainThreadTasks = require('lighthouse/lighthouse-core/lib/tracehouse/main-thread-tasks'),
        fs = require('fs');

class MainThreadAnalyzer {
  constructor({ 
    traceFilePath, 
    domInteractive, 
    domComplete, 
    urlPattern = null, 
    urlPatterns = null,
    msToConsiderBlocking = 50
  }) {
    if(!urlPattern && !urlPatterns) throw new Error('Must provide either `urlPattern` or `urlPatterns` argument.');
    this.urlPatterns = urlPatterns || [urlPattern];
    this.traceFilePath = traceFilePath;
    this.domInteractive = domInteractive;
    this.domComplete = domComplete;
    console.log(`DOM INTERACTIVE! ${this.domInteractive}`);
    this.msToConsiderBlocking = msToConsiderBlocking;

    this.allMainThreadExecutionsMs = 0;
    this.allMainThreadBlockingExecutionMs = 0;
    this.totalMainThreadExecutionMsForUrlPatterns = 0;
    this.totalMainThreadBlockingMsForUrlPatterns = 0;
    this.longTasksForUrlPatterns = [];
    this.mainThreadExecutions = [];
    this.mainThreadExecutionBeforeDomInteractive = 0;
    this.mainThreadExecutionBeforeDomComplete = 0;
  }

  get parsedTrace() {
    if(this._parsedTrace) return this._parsedTrace;
    console.log(`Parsing trace file from ${this.traceFilePath}`);
    let rawTrace = JSON.parse(fs.readFileSync(this.traceFilePath));
    if(!rawTrace.traceEvents) rawTrace = { traceEvents: rawTrace };
    return this._parsedTrace = TraceParser.processTrace(rawTrace);
  }

  get mainThreadTasks() {
    if(this._mainThreadTasks) return this._mainThreadTasks;
    console.log(`Gathering all main thread tasks`);
    return this._mainThreadTasks = MainThreadTasks.getMainThreadTasks(
      this.parsedTrace.mainThreadEvents, 
      this.parsedTrace.frames, 
      this.parsedTrace.timestamps.traceEnd
    )
  }

  gatherMainThreadExecutionMetrics = () => {
    console.log(`Calculating main thread execution time and blocking tasks for ${JSON.stringify(this.urlPatterns)}`);
    if(!fs.existsSync(this.traceFilePath)) throw Error(`No such trace file ${this.traceFilePath}`);

    console.log(`FIRST MAIN THREAD TASK?? ${this.mainThreadTasks[0]}`);
    this.mainThreadTasks.forEach(this._recordMainThreadTask);

    return {
      allMainThreadExecutionsMs: this.allMainThreadExecutionsMs,
      allMainThreadBlockingExecutionMs: this.allMainThreadBlockingExecutionMs,
      totalMainThreadExecutionMsForUrlPatterns: this.totalMainThreadExecutionMsForUrlPatterns,
      totalMainThreadBlockingMsForUrlPatterns: this.totalMainThreadBlockingMsForUrlPatterns,
      mainThreadExecutionBeforeDomInteractiveForUrlPatterns: this.mainThreadExecutionBeforeDomInteractive,
      mainThreadExecutionBeforeDomCompleteForUrlPatterns: this.mainThreadExecutionBeforeDomComplete,
      longTasksForUrlPatterns: this.longTasksForUrlPatterns,
      mainThreadExecutions: this.mainThreadExecutions
    };
  }

  _recordMainThreadTask = task => {
    this.allMainThreadExecutionsMs += task.selfTime;
    if(task.selfTime >= this.msToConsiderBlocking) this.allMainThreadBlockingExecutionMs += task.selfTime;
    if(this._taskIsAttributableToUrlPatterns(task)) {
      this.totalMainThreadExecutionMsForUrlPatterns += task.selfTime;
      this.mainThreadExecutions.push(this._formattedTask(task));
      if(task.startTime < this.domInteractive) this.mainThreadExecutionBeforeDomInteractive += task.selfTime;
      if(task.startTime < this.domComplete) this.mainThreadExecutionBeforeDomComplete += task.selfTime;
      if(task.selfTime >= this.msToConsiderBlocking) {
        this.totalMainThreadBlockingMsForUrlPatterns += task.selfTime;
        this.longTasksForUrlPatterns.push(this._formattedTask(task));
      }
    }
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

  _taskIsAttributableToUrlPatterns = task => {
    return typeof task.attributableURLs.find(
      attributableUrl => this.urlPatterns.find(
        urlPattern => attributableUrl.includes(urlPattern)
      )
    ) === 'string'
  }

  // _mainThreadTasksForUrlPatterns = urlPatterns => {
  //   return this.mainThreadTasks.filter(task => this._taskIsAttributableToUrlPattern(task, urlPatterns))
  // }

  // _recursiveChildrenForTask = task => {
  //   try {
  //     if(!task.children || task.children.length === 0) return [];
  //     return task.children.map(childTask => this._formattedTask(childTask))
  //   } catch(err) {
  //     console.log(`Error in recursion!! ${err.message}`);
  //     throw new Error(err);
  //   }
  // }

  // _recursiveParentsForTask = task => {
  //   try {
  //     if(!task.parent || task.parent === {}) return {};
  //     return this._formattedTask(task.parent);
  //   } catch(err) {
  //     console.log(`Error in recursion!! ${err.message}`);
  //     throw new Error(err);
  //   }
  // }
  
  // totalMainThreadExecutionTimeForUrl = (...urlPatterns) => {
  //   console.log(`Calculating total main thread execution tasks for ${urlPattern}`);
  //   if(!fs.existsSync(this.traceFilePath)) return;
  //   let executionMs = 0;
  //   this._mainThreadTasksByUrlPattern(urlPatterns).forEach(task => executionMs += task.selfTime);
  //   return executionMs;
  // }

  // tasksForUrlSlowerThan = (...urlPatterns, ms) => {
  //   console.log(`Calculating main thread tasks for ${JSON.stringify(urlPatterns)} longer than ${ms} ms.`);
  //   if(!fs.existsSync(this.traceFilePath)) return;
  //   return this.mainThreadTasks
  //                 .filter(task => task.selfTime > ms && typeof task.attributableURLs.find(attributableUrl => urlPatterns.find(urlPattern => attributableUrl.includes(urlPattern))) === 'string')
  //                 .map(task => {
  //                   return {
  //                     duration: task.duration, 
  //                     selfTime: task.selfTime,
  //                     startTime: task.startTime,
  //                     endTime: task.endTime,
  //                     event: task.event,
  //                     group: task.group
  //                   }
  //                 });
  // }

  // _mainThreadTasksByUrlPattern = (...urlPatterns) => this.tasksForUrlSlowerThan(urlPatterns, -1);
}

module.exports = MainThreadAnalyzer;