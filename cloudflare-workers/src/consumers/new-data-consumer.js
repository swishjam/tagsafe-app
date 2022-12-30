export default async function newDataConsumer(messages, env) {
  console.log(`newTagsConsumer ${messages.length} messages received`);
  
  const fetchPromises = messages.map(message => sendDataToResqueConnector(message, env.RESQUE_CONNECTOR_LAMBDA_FUNCTION_URL));

  const fetchResults = await Promise.all(fetchPromises);
  const failedRequest = fetchResults.find(resp => !resp.ok)

  if(failedRequest) {
    throw new Error(`
      Fetch request to Lambda Redis Connector failed:
      ${await failedRequest.text()}
    `)
  }

  console.log(`Sent ${messages.length} new tag batches into Redis consumer!`)
  return { status: 200, numMessages: messages.length }
}

async function sendDataToResqueConnector(message, lambdaEndpoint) {
  const reqBody = {
    tagsafe_consumer_resque_queue: 'tagsafe_js_events',
    tagsafe_consumer_resque_klass: 'TagsafeJsDataConsumerJob',
    data: {
      enqueued_at_ts: new Date(),
      event_type: message.eventType || 'NewTags',
      cloudflare_message_id: message.id,
      ...message.body
    }
  };
  return fetch(lambdaEndpoint, {
    method: 'POST',
    headers: { 'Content-type': 'application/json' },
    body: JSON.stringify(reqBody)
  })
}