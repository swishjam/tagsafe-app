'use strict';

const DataStoreManager = require('./src/dataStoreManager'),
        ReleaseConfig = require('./src/releaseCheckConfig'),
        ReleaseCheckResults = require('./src/releaseCheckResults'),
        ReleaseCheckRunner = require('./src/releaseCheckRunner'),
        ResqueEnqueuer = require('./src/resqueEnqueuer'),
        calcLambdaCost = require('./src/lambdaCostCalcaultor'),
        crypto = require('crypto');

const checkTagsForReleases = async (event, context) => {
  const batchUid = [1,2,3,4].map(() => crypto.randomBytes(2).toString('hex')).join('-');
  console.log(`Running release check on the ${event.current_minute_interval} minute interval tags.`);
  console.log(`Batch UID: ${batchUid}`);
  const startDate = new Date();
  context.serverlessSdk.tagEvent('minute-interval', event.current_minute_interval);
  context.serverlessSdk.tagEvent('batch-uid', batchUid);
  
  const dataStore = new DataStoreManager();
  const tagConfigurationsForRegionAndInterval = await dataStore.getReleaseCheckConfigurationsForInterval(event.current_minute_interval);
  
  const resultsWithNewVersions = [];
  const resultsWithoutNewVersions = [];
  const numTags = tagConfigurationsForRegionAndInterval.length;

  console.log(`Checking releases for ${numTags} tags that are configured for ${event.current_minute_interval} minute checks.`);
  for(let i = 0; i < tagConfigurationsForRegionAndInterval.length; i++) {
    const jsonTagConfig = tagConfigurationsForRegionAndInterval[i];
    const releaseCheckConfig = new ReleaseConfig({
      jsonConfig: jsonTagConfig, 
      minuteInterval: event.current_minute_interval
    });
    context.serverlessSdk.tagEvent('should-check-for-new-release', releaseCheckConfig.shouldCheckForNewRelease);

    const releaseCheckRunner = new ReleaseCheckRunner({
      releaseCheckConfig: releaseCheckConfig,
      dataStoreManager: dataStore,
      resultsWithNewVersionsArray: resultsWithNewVersions,
      resultsWithoutNewVersionsArray: resultsWithoutNewVersions,
      tagEvent: context.serverlessSdk.tagEvent,
      span: context.serverlessSdk.span
    });
    await releaseCheckRunner.runReleaseCheck();
  }

  const msToComplete = new Date() - startDate;
  const formattedResults = {
    batch_uid: batchUid,
    interval: event.current_minute_interval,
    tagsafe_consumer_klass: 'StepFunctionResponses::ReleaseChecksResult',
    aws_region: process.env.AWS_REGION,
    total_num_tags_checked: numTags, 
    num_tags_with_new_versions: resultsWithNewVersions.length,
    num_tags_without_new_versions: resultsWithoutNewVersions.length,
    ms_to_complete_all_checks: msToComplete,
    executed_at: startDate,
    aws_request_id: context.awsRequestId,
    aws_log_group_name: context.logGroupName,
    aws_log_stream_name: context.logStreamName,
    aws_trace_id: process.env._X_AMZN_TRACE_ID,
    aws_estimated_lambda_cost: calcLambdaCost(msToComplete)
  }

  const releaseCheckBatchId = await dataStore.createReleaseCheckBatch({ 
    batchUid: batchUid, 
    minuteInterval: event.current_minute_interval,
    numTagsWithNewVersions: resultsWithNewVersions.length, 
    numTagsWithoutNewVersions: resultsWithoutNewVersions.length, 
    executedAtDate: startDate
  });
  if(resultsWithNewVersions.length > 0) {
    const formattedNewVersionResults = Object.assign({}, formattedResults, { is_for_new_tag_versions: true, release_check_results: resultsWithNewVersions })
    const resqueEnqueuer = new ResqueEnqueuer({ tagsafeConsumerArgs: formattedNewVersionResults, tagsafeResqueQueue: 'critical' });
    await resqueEnqueuer.enqueueIntoTagsafeResque();
  } 
  if(resultsWithoutNewVersions.length > 0) {
    const formattedNoNewVersionResults = new ReleaseCheckResults(releaseCheckBatchId, resultsWithoutNewVersions).formattedResults();
    await dataStore.insertReleaseCheckResults(formattedNoNewVersionResults);
  }

  console.log(`Formatted results without release data: ${JSON.stringify(formattedResults)}`);
  console.log('============================================')
  console.log(`==== Complete Release Monitoring batch! ====`);
  console.log(`====           Tags checked: ${numTags}          ====`);
  console.log(`====        Releases detected: ${resultsWithNewVersions.length}        ====`);
  console.log('============================================')
  return Object.assign({}, formattedResults, { resultsWithNewVersions: resultsWithNewVersions, resultsWithoutNewVersions: resultsWithoutNewVersions });
};

const checkTagForRelease = async (event, context) => {
  if(!event.tag_id) {
    throw new Error('checkTagForRelease missing required `tag_id` argument.');
  }

  console.log(`
    Running release check on single tag (ID: ${event.tag_id}). 
    Sending results to the Tagsafe ${event.tagsafe_resque_consumer_queue || process.env.DEFAULT_TAGSAFE_CONSUMER_JOB_QUEUE} Resque queue.
  `);
  const startDate = new Date();
  
  const dataStore = new DataStoreManager();
  const tagReleaseCheckJsonConfig = await dataStore.getTagConfiguration(event.tag_id);
  if(tagReleaseCheckJsonConfig) {
    const resultsWithNewVersions = [];
    const resultsWithoutNewVersions = [];
  
    const releaseCheckConfig = new ReleaseConfig({
      jsonConfig: tagReleaseCheckJsonConfig, 
      tagId: event.tag_id,
    });
  
    const releaseCheckRunner = new ReleaseCheckRunner({
      releaseCheckConfig: releaseCheckConfig,
      dataStoreManager: dataStore,
      resultsWithNewVersionsArray: resultsWithNewVersions,
      resultsWithoutNewVersionsArray: resultsWithoutNewVersions,
      tagEvent: context.serverlessSdk.tagEvent,
      span: context.serverlessSdk.span
    });
    
    await releaseCheckRunner.runReleaseCheck();
    await dataStore.killConnection();
  
    const msToComplete = Date.now() - startDate;
    const formattedResults = {
      tagsafe_consumer_klass: 'LambdaEventResponses::TagChecksResult',
      aws_region: process.env.AWS_REGION,
      only_check_uptime: false,
      total_num_tags_checked: 1, 
      ms_to_complete_all_checks: msToComplete,
      aws_request_id: context.awsRequestId,
      aws_log_group_name: context.logGroupName,
      aws_log_stream_name: context.logStreamName,
      aws_trace_id: process.env._X_AMZN_TRACE_ID,
      aws_estimated_lambda_cost: calcLambdaCost(msToComplete)
    }
    if(resultsWithNewVersions.length > 0) {
      const formattedNewVersionResults = Object.assign({}, formattedResults, { is_for_new_tag_versions: true, tag_check_results: resultsWithNewVersions })
      const resqueEnqueuer = new ResqueEnqueuer({ tagsafeConsumerArgs: formattedNewVersionResults, tagsafeResqueQueue: event.tagsafe_resque_consumer_queue || process.env.DEFAULT_TAGSAFE_CONSUMER_JOB_QUEUE });
      await resqueEnqueuer.enqueueIntoTagsafeResque();
    } 
    if(resultsWithoutNewVersions.length > 0) {
      const formattedNoNewVersionResults = Object.assign({}, formattedResults, { is_for_new_tag_versions: false, tag_check_results: resultsWithoutNewVersions })
      const resqueEnqueuer = new ResqueEnqueuer({ tagsafeConsumerArgs: formattedNoNewVersionResults, tagsafeResqueQueue: event.tagsafe_resque_consumer_queue || process.env.DEFAULT_TAGSAFE_CONSUMER_JOB_QUEUE });
      await resqueEnqueuer.enqueueIntoTagsafeResque();
    }
    console.log('\n=============================================')
    console.log(`==== Completed Release Check for Tag ${event.tag_id} ====`);
    console.log(`====       Release detected? ${resultsWithNewVersions.length > 0}       ====`);
    console.log('=============================================\n')
    return Object.assign({}, formattedResults, { resultsWithNewVersions: resultsWithNewVersions, resultsWithoutNewVersions: resultsWithoutNewVersions });
  } else {
    await dataStore.killRedisConnection();
    throw new Error(`Tag ID ${event.tag_id} is not present in Redis data store ${process.env.REDIS_URL}`)
  }
}

module.exports = {
  checkTagsForReleases: checkTagsForReleases,
  checkTagForRelease: checkTagForRelease
}