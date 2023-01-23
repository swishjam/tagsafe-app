const MainThreadAnalyzer = require("./src/mainThreadAnalyzer");
const PuppeteerModerator = require("./src/puppeteerModerator");
const ScriptManipulator = require('./src/scriptManipulator');
const Tracer = require("./src/tracer");

module.exports.handle = async (event, _context) => {
  const { 
    page_url, 
    tag_url, 
    tag_url_loading_strategy,
    tag_url_patterns_to_block,
    main_thread_blocking_multiplier = 0.2,
    total_main_thread_execution_multiplier = 0.1,
    navigation_wait_until = 'networkidle0' 
  } = event;

  if (!page_url || !tag_url || !tag_url_loading_strategy || !tag_url_patterns_to_block) {
    throw new Error('\
      Invalid invocation, missing required args. \
      MainThreadExecutionEvaluator must be called with `page_url`, `tag_url`, `tag_url_loading_strategy`, and `tag_url_patterns_to_block`. \
    ')
  }

  const puppeteerModerator = new PuppeteerModerator()
  const page = await puppeteerModerator.launch();

  const scriptManipulator = new ScriptManipulator({
    page,
    urlPatternsToBlock: tag_url_patterns_to_block,
    urlToInject: tag_url,
    urlToInjectLoadStrategy: tag_url_loading_strategy,
  })

  const tracer = new Tracer({ page, filename: `${tag_url.replace(/\/|\:|\\|\./g, '_')}-${Date.now()}` });

  await Promise.all([
    scriptManipulator.blockRequestsToUrlPatterns(),
    scriptManipulator.injectScriptOnNewDocument(),
    tracer.startTracing()
  ])

  console.log(`Going to ${page_url}......`);
  await page.goto(page_url, { waituntil: navigation_wait_until });
  console.log(`Arrived at ${page_url}! Calculating main thread......`);

  await new Promise(r => setTimeout(r, parseInt(process.env.ADDITIONAL_WAIT_TIME_AFTER_NAVIGATION || 5_000)));

  await tracer.stopTracing();
  const mainThreadResults = new MainThreadAnalyzer(tracer.localFilePath).mainThreadExecutionForUrl(tag_url);
  tracer.purgeLocalFile();

  await puppeteerModerator.shutdown();

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
