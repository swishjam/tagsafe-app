'use strict';

require('dotenv').config();

const ResqueEnqueuer = require('./src/resqueEnqueuer');

const handle = async request => {
  console.log(`Received resque-connector request! ${JSON.stringify(request)}`);
  const { 
    data, 
    tagsafe_consumer_resque_queue, 
    tagsafe_consumer_resque_klass
  } = JSON.parse(request.body);
  console.log(`data: ${data}`)

  const resqueEnqueuer = new ResqueEnqueuer({
    tagsafeConsumerResqueQueue: tagsafe_consumer_resque_queue,
    tagsafeConsumerResqueKlass: tagsafe_consumer_resque_klass
  });
  await resqueEnqueuer.enqueueData(data);
  
  return {
    status: 200,
    num_records: data.length
  }
}


module.exports = { handle }