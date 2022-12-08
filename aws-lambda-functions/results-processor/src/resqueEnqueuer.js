const { createClient } = require('redis');

class ResqueEnqueuer {
  constructor(resqueArgs, { 
    tagsafeRedisUrl = process.env.TAGSAFE_REDIS_URL,
    tagsafeResqueQueue = process.env.DEFAULT_TAGSAFE_CONSUMER_JOB_QUEUE, 
    redisConnectTimeoutMs = parseInt(process.env.REDIS_CONNECT_TIMEOUT_MS || 4_000) 
  }) {
    this.resqueArgs = resqueArgs;
    this.tagsafeRedisUrl = tagsafeRedisUrl;
    this.tagsafeResqueQueue = tagsafeResqueQueue;
    this.tagsafeResqueReceiverJobClass = "ProcessReceivedLambdaEventJob";
    this.sentSuccessfully = false;
    this.redisConnectTimeoutMs = redisConnectTimeoutMs;
    this.resqueJobId = this._generateResqueJobId();
  }

  initializeRedis = () => {
    console.log(`Connecting to Redis client at ${this.tagsafeRedisUrl}`);
    this.redis = createClient({ url: this.tagsafeRedisUrl });
    this.redis.on('error', err => console.error(`Redis client encountered an error: ${err}`) );
    this.redis.on('connect', () => console.log('Initiating Redis connection...') )
    this.redis.on('ready', async () => console.log(`Redis successfully connected`) );
    this.redis.on('end', () => console.log('Redis disconnected') );
    this.redis.on('reconnecting', () => console.log('Attempting to re-connect to Redis...') );
  }

  _connectToRedisOrThrowError = async () => {
    setTimeout(() => {
      if(!this.connectedToRedis) {
        throw new Error(`Unable to connect to Redis (${this.tagsafeRedisUrl}) within ${this.redisConnectTimeoutMs / 1_000} seconds.`);
      }
    }, this.redisConnectTimeoutMs);
    const start = Date.now();
    this.initializeRedis();
    await this.redis.connect();
    this.connectedToRedis = true;
    console.log(`Connected to Redis in ${Date.now() - start} ms.`);
  }

  enqueueIntoTagsafeResque = async () => {
    try {
      await this._connectToRedisOrThrowError();
  
      const tagsafeFormattedResqueJob = {
        "class": "ActiveJob::QueueAdapters::ResqueAdapter::JobWrapper",
        "args": [
          {
            "job_class": this.tagsafeResqueReceiverJobClass,
            "job_id": this.resqueJobId,
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
      await this.redis.rPush(`resque:queue:${this.tagsafeResqueQueue}`, JSON.stringify(tagsafeFormattedResqueJob));
      this.sentSuccessfully = true;
      await this.killRedisConnection();
      console.log(`Sent data into Resque ${this.tagsafeResqueQueue} queue.`);
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