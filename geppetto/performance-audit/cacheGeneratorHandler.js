const CacheGenerator = require('./src/cacher/generator'),
        EventConfig = require('./src/eventConfig'),
        ImageScrubber = require('./src/scrubbers/imageScrubber'),
        MonkeyPatcher = require('./src/pageManipulators/monkeyPatcher'),
        PageEventHandler = require('./src/pageEventHandler'),
        PageManipulator = require('./src/pageManipulators/pageManipulator'),
        PuppeteerModerator = require('./src/puppeteerModerator'),
        RequestInterceptor = require('./src/requestInterceptor'),
        TagInjector = require('./src/pageManipulators/tagInjector'),
        ThirdPartyTagDetector = require('./src/thirdPartyTagDetector'),
        ThirdPartyTagScrubber = require('./src/scrubbers/thirdPartyTagScrubber'),
        ValidityChecker = require('./src/validityChecker');

require('dotenv').config();

const generateCache = async (event, context) => {
  const startTime = Date.now();
  const {
    allowAllThirdPartyTags,
    firstPartyRequestUrl,
    pageUrlToGenerateCacheFrom,
    scrollPage,
    stripAllImages,
    thirdPartyTagUrlsAndRulesToInject,
    thirdPartyTagUrlPatternsToAllow
  } = new EventConfig(event).constructCacheGeneratorConfig();

  const puppeteerModerator = new PuppeteerModerator();
  const page = await puppeteerModerator.launch();

  const pageEventHandler = new PageEventHandler(page);
    
  const thirdPartyTagDetector = new ThirdPartyTagDetector({ 
    firstPartyUrl: firstPartyRequestUrl, 
    urlPatternsToAllow: thirdPartyTagUrlPatternsToAllow,
    allowAllThirdPartyTags: allowAllThirdPartyTags
  });

  const pageManipulator = new PageManipulator({ 
    page: page,
    pageUrl: pageUrlToGenerateCacheFrom, 
    tagsAndRulesToInject: thirdPartyTagUrlsAndRulesToInject,
    thirdPartyTagDetector: thirdPartyTagDetector,
    overrideInitialHTMLRequestWithManipulatedPage: true,
    tagInjector: new TagInjector(thirdPartyTagUrlsAndRulesToInject),
    monkeyPatcher: new MonkeyPatcher(thirdPartyTagDetector),
    imageScrubber: new ImageScrubber({ stripAllImages: stripAllImages, pageEventHandler: pageEventHandler }),
    thirdPartyTagScrubber: new ThirdPartyTagScrubber({ thirdPartyTagDetector: thirdPartyTagDetector, pageEventHandler: pageEventHandler })
  });

  const requestInterceptor = new RequestInterceptor({ 
    page: page,
    shouldGenerateCache: true,
    pageManipulator: pageManipulator, 
    thirdPartyTagDetector: thirdPartyTagDetector,
    pageEventHandler: pageEventHandler,
    blockImageRequests: stripAllImages
  });

  const validityChecker = new ValidityChecker({
    page: page,
    ensureInjectedTagHasLoaded: thirdPartyTagUrlsAndRulesToInject.length > 0,
    throwErrorIfDOMCompleteIsZero: true
  })
  
  const cacheGenerator = new CacheGenerator({
    page: page,
    pageUrl: pageUrlToGenerateCacheFrom,
    pageManipulator: pageManipulator,
    requestInterceptor: requestInterceptor,
    thirdPartyTagDetector: thirdPartyTagDetector,
    validityChecker: validityChecker,
    scrollPage: scrollPage,
    networkToEmulate: 'Regular4G'
  });

  // try {
    await cacheGenerator.generateCache();
    await puppeteerModerator.shutdown();
  // } catch(err) {
  //   await puppeteerModerator.shutdown();
  //   console.trace();
  //   throw Error(err);
  // }

  const costPerGigabyteMs = 0.0000166667 / 1_000;
  const allocatedGigabytes = parseInt(process.env.AWS_LAMBDA_FUNCTION_MEMORY_SIZE) / 1_000;
  const executionTimeMs = Date.now() - startTime;
  const estimatedCost = costPerGigabyteMs * allocatedGigabytes * executionTimeMs;

  return { 
    cached_responses_s3_location: cacheGenerator.cachedResponsesS3Location,
    execution_time_ms: executionTimeMs,
    aws_request_id: context.awsRequestId,
    aws_log_stream_name: context.logStreamName,
    aws_trace_id: process.env._X_AMZN_TRACE_ID,
    aws_estimated_lambda_cost: estimatedCost
  }
}

module.exports.generateCache = generateCache;