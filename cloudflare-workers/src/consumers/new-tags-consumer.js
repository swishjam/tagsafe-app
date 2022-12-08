export default async function newTagsConsumer(messages) {
  console.log(`newTagsConsumer ${messages.length} messages received`)
  
  const fetchPromises = messages.map(sendDataToResqueConnector);

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

async function sendDataToResqueConnector(message) {
  const reqBody = {
    tagsafe_consumer_resque_queue: 'critical',
    tagsafe_consumer_resque_klass: 'TagsafeJsEventsConsumerJob',
    data: {
      event_type: message.eventType || 'NewTags',
      cloudflare_message_id: message.id,
      ...message.body
    }
  };
  return fetch('https://agtt4yi2qms6vl7zdnqlgiatzu0udzmp.lambda-url.us-east-1.on.aws/', {
    method: 'POST',
    headers: { 'Content-type': 'application/json' },
    body: JSON.stringify(reqBody)
  })
}