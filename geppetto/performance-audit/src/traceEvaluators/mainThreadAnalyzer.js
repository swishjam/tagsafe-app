const TraceParser = require('lighthouse/lighthouse-core/lib/tracehouse/trace-processor'),
        MainThreadTasks = require('lighthouse/lighthouse-core/lib/tracehouse/main-thread-tasks'),
        fs = require('fs');

class MainThreadAnalyzer {
  constructor(traceFilePath) {
    this.traceFilePath = traceFilePath;
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

  mainThreadExecutionForUrl = (urlPatterns, msToConsiderBlocking = 50) => {
    urlPatterns = typeof urlPatterns === 'string' ? [urlPatterns] : urlPatterns;
    console.log(`Calculating main thread execution time and blocking tasks for ${JSON.stringify(urlPatterns)}`);
    if(!fs.existsSync(this.traceFilePath)) return;
    let allMainThreadExecutionsMs = 0;
    let allMainThreadBlockingExecutionMs = 0;
    let totalExecutionMsForUrlPatterns = 0;
    let totalMainThreadBlockingMsForUrlPatterns = 0;
    let longTasksForUrlPatterns = [];
    // let totalExecutionMsByTag = {};
    // let blockingExecutionMsByTag = {};
    this.mainThreadTasks.forEach(task => {
      allMainThreadExecutionsMs += task.selfTime;
      if(task.selfTime >= msToConsiderBlocking) allMainThreadBlockingExecutionMs += task.selfTime;
      if(this._taskIsAttributableToUrlPatterns(task, urlPatterns)) {
        totalExecutionMsForUrlPatterns += task.selfTime;
        if(task.selfTime >= msToConsiderBlocking) {
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