const MainThreadAnalyzer = require("./src/mainThreadAnalyzer");
const PuppeteerModerator = require("./src/puppeteerModerator");
const RequestInterceptor = require('./src/requestInterceptor');
const Tracer = require("./src/tracer");

module.exports.handle = async (event, _context) => {
  const { 
    page_url, 
    tag_url, 
    request_url_to_overwrite,
    request_url_to_overwrite_to,
    main_thread_blocking_multiplier = 0.2,
    total_main_thread_execution_multiplier = 0.1,
    navigation_wait_until = 'networkidle0' 
  } = event;

  if(!page_url || !tag_url || !request_url_to_overwrite || !request_url_to_overwrite_to) {
    throw new Error('\
      Invalid invocation, missing required args. \
      MainThreadExecutionEvaluator must be called with `page_url`, `tag_url`, `request_url_to_overwrite`, and `request_url_to_overwrite_to`. \
    ')
  }

  const puppeteerModerator = new PuppeteerModerator()
  const page = await puppeteerModerator.launch();


  const requestOverrideMap = {}
  requestOverrideMap[request_url_to_overwrite] = request_url_to_overwrite_to;
  console.log(`Going to overwrite ${request_url_to_overwrite} -> ${request_url_to_overwrite_to}`);
  const requestInterceptor = new RequestInterceptor({ page, requestOverrideMap });
  await requestInterceptor.overrideProvidedRequests();

  const tracer = new Tracer({ page, filename: `${tag_url.replace(/\/|\:|\\|\./g, '_')}-${Date.now()}` });
  await tracer.startTracing();

  console.log(`Going to ${page_url}......`);
  await page.goto(page_url, { waituntil: navigation_wait_until });
  console.log(`Arrived at ${page_url}! Calculating main thread......`);

  await new Promise(r => setTimeout(r, parseInt(process.env.ADDITIONAL_WAIT_TIME_AFTER_NAVIGATION || 2000)));

  await tracer.stopTracing();
  const mainThreadResults = new MainThreadAnalyzer(tracer.localFilePath).mainThreadExecutionForUrl(tag_url);
  tracer.purgeLocalFile();

  await puppeteerModerator.shutdown();
  if (!requestInterceptor.didOverwriteRequest()) throw new Error(`Cannot calculate Main Thread Execution, ${request_url_to_overwrite} not present on ${page_url}.`)

  let score = 100 - 
                mainThreadResults.totalExecutionMsForUrlPatterns * parseFloat(total_main_thread_execution_multiplier) -
                mainThreadResults.totalMainThreadBlockingMsForUrlPatterns * parseFloat(main_thread_blocking_multiplier);
  score = score < 0 ? 0 : score;

  const responsePayload = {
    score,
    raw_results: {
      all_main_thread_executions_ms: mainThreadResults.allMainThreadBlockingExecutionMs,
      all_main_thread_blocking_ms: mainThreadResults.allMainThreadBlockingExecutionMs,
      total_main_thread_execution_ms_for_tag: mainThreadResults.totalExecutionMsForUrlPatterns,
      total_main_thread_blocking_ms_for_tag: mainThreadResults.totalMainThreadBlockingMsForUrlPatterns,
      long_tasks_for_tag: mainThreadResults.longTasksForUrlPatterns
    }
  }

  return { responsePayload, requestPayload: event };
}
