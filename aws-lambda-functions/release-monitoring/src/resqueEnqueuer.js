const RedisClient = require('./redisClient');

class ResqueEnqueuer {
  constructor({ tagsafeConsumerArgs, tagsafeResqueQueue }) {
    this.resqueArgs = tagsafeConsumerArgs;
    this.tagsafeResqueQueue = tagsafeResqueQueue;
    this.tagsafeResqueReceiverJobClass = "ProcessReceivedLambdaEventJob";
    this.sentSuccessfully = false;
  }

  enqueueIntoTagsafeResque = async () => {
    try {
      const redisClient = new RedisClient(process.env.TAGSAFE_RECEIVER_REDIS_URL);
      this.redis = await redisClient.client()
  
      const tagsafeFormattedResqueJob = {
        "class": "ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper",
        "args": [
          {
            "job_class": this.tagsafeResqueReceiverJobClass,
            "job_id": this._generateResqueJobId(),
            "provider_job_id": null,
            "queue_name": this.tagsafeResqueQueue,
            "priority": null,
            "arguments": [this.resqueArgs],
            "executions":0,
            "exception_executions":{},
            "locale":"en",
            "timezone":"Pacific Time (US \u0026 Canada)",
            "enqueued_at":`${new Date()}`
          }
        ]
      };
      // if(process.env.IS_LOCAL === 'true') {
      //   console.log(`Mocking push to Resque with: ${JSON.stringify(tagsafeFormattedResqueJob)}`);
      // } else {
        await this.redis.rPush(`resque:queue:${this.tagsafeResqueQueue}`, JSON.stringify(tagsafeFormattedResqueJob));
      // }
      this.sentSuccessfully = true;
      console.log(`Sent data into Resque ${this.tagsafeResqueQueue} queue.`);
      await this.killRedisConnection();
      return tagsafeFormattedResqueJob;
    } catch(err) {
      console.error(`Encountered error in enqueueIntoTagsafeResque: ${err}`);
      await this.killRedisConnection();
      throw new Error(err);
    }
  }

  killRedisConnection = async () => {
    if(this.redis && this.redis.isOpen) await this.redis.quit();
  }
  
  _generateResqueJobId = () => {
    return [
      [
        'aws0',
        [...Array(4)].map(() => Math.floor(Math.random() * 16).toString(16)).join('')
      ].join(''),
      [...Array(4)].map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
      [...Array(4)].map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
      [...Array(12)].map(() => Math.floor(Math.random() * 16).toString(16)).join('')
    ].join('-');
  }
}

module.exports = ResqueEnqueuer;