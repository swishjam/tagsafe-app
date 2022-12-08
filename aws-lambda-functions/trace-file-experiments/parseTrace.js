const TraceProcessor = require('lighthouse/lighthouse-core/lib/tracehouse/trace-processor'),
        MainThreadTasks = require('lighthouse/lighthouse-core/lib/tracehouse/main-thread-tasks'),
        BootupTime = require('lighthouse/lighthouse-core/audits/bootup-time'),
        // CPUProfiler = require('lighthouse/lighthouse-core/lib/tracehouse/cpu-profile-model'),
        // UserTimings = require('lighthouse/lighthouse-core/computed/user-timings'),
        fs = require('fs');


let trace = JSON.parse(fs.readFileSync('./timeline.json'));

if(!trace.traceEvents) trace = { traceEvents: trace };

const processedTrace = TraceProcessor.processTrace(trace);

const navigationEvents = TraceProcessor.processNavigation(processedTrace);
// const cpuProfiler = CPUProfiler.collectProfileEvents(trace.traceEvents);
const mainThreadTasks = MainThreadTasks.getMainThreadTasks(
  processedTrace.mainThreadEvents, 
  processedTrace.frames, 
  processedTrace.timestamps.traceEnd
)

const mainThreadTasksByUrl = urlPattern => mainThreadTasks.filter(task => task.attributableURLs.some(url => url.includes(urlPattern)));

const getMainThreadExecutionsForUrl = url => {
  const mainThreadTasksForUrl = mainThreadTasksByUrl(url);
  let executionMs = 0;
  for (const task of mainThreadTasksForUrl) {
    executionMs += task.selfTime;
  }
  mainThreadTasksForUrl.sort((a, b) => b.selfTime - a.selfTime)
  return {
    totalExecutionMs: executionMs,
    // sortedLongTasks: mainThreadTasksForUrl,
    topTenLongestTasks: mainThreadTasksForUrl.slice(0, 10)
  };
}

// const qmTasks = mainThreadTasksByUrl('cdn.quantummetric.com');

console.log(`Navigation Events:`);
console.log(navigationEvents);

// console.log(`\n\nMain thread tasks:`);
// console.log(mainThreadTasks);

// console.log(`\n\nQM execution time??`);
// const longTasks = getMainThreadExecutionsForUrl('cdn.quantummetric.com');
// // console.log(longTasks);
// // console.log(qmTasks.map( task => task.group?.traceEventNames ));
// console.log('\n\nLongest QM task:')
// console.log(longTasks.topTenLongestTasks[0])