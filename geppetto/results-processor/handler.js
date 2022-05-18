'use strict';

require('dotenv').config();

const ResqueEnqueuer = require('./src/resqueEnqueuer');

const handleResultsFromSqs = async (event, context) => {
  console.log(`Beginning send-results-to-tagsafe with ${event.Records.length} records from SQS`);
  for(let i = 0; i < event.Records.length; i++) {
    const record = event.Records[i];
    const event = JSON.parse(record.body);
    await handle(event, context);
  }
  console.log('Completed pulling records from SQS')
}

const handle = async (event, context) => {
  context.serverlessSdk.tagEvent('executed-step-function-uid', event.detail?.requestPayload?.executed_step_function_uid || event.requestPayload?.executed_step_function_uid || 'none');

  const tagsafeRedisUrl = event.detail?.requestPayload?.tagsafe_consumer_redis_url || 
                            event.requestPayload?.tagsafe_consumer_redis_url || 
                            process.env.TAGSAFE_REDIS_URL;
  const tagsafeResqueQueueToSendTo = event.detail?.requestPayload?.ProcessReceivedLambdaEventJobQueue || 
                                      event.requestPayload?.ProcessReceivedLambdaEventJobQueue || 
                                      process.env.DEFAULT_TAGSAFE_CONSUMER_JOB_QUEUE;
  const resqueEnqueuer = new ResqueEnqueuer(event, { 
    tagsafeRedisUrl: tagsafeRedisUrl,
    tagsafeResqueQueue: tagsafeResqueQueueToSendTo 
  });

  const res = await resqueEnqueuer.enqueueIntoTagsafeResque();
  context.serverlessSdk.tagEvent('number-of-redis-connections', resqueEnqueuer.numConnections);
  const results = {
    status_code: 202,
    tagsafe_formatted_resque_job: res,
    num_redis_connections: resqueEnqueuer.numConnections
  };
  console.log(`Completed with results: ${JSON.stringify(results)}`);
  return results;
}


module.exports = {
  handleResultsFromSqs: handleResultsFromSqs,
  handle: handle
}